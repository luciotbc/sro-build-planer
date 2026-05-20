module CharacterMasteries
  class UpdateService
    def self.call(character, params) = new(character, params).call

    def initialize(character, params)
      @character = character
      @params = params
      @warnings = []
    end

    def call
      cm =
        CharacterMastery.includes(:mastery).find_by(
          character: @character,
          mastery_id: @params[:mastery_id]
        )
      unless cm
        return ServiceResult.fail(errors: ["CharacterMastery not found"])
      end

      @mastery = cm.mastery

      new_current =
        @params.fetch(:current_mastery_level, cm.current_mastery_level)
      new_target = @params.fetch(:target_mastery_level, cm.target_mastery_level)

      ActiveRecord::Base.transaction do
        if @params.key?(:current_mastery_level)
          sync_character_level(:current_level, new_current)
        end
        if @params.key?(:target_mastery_level)
          sync_character_level(:target_level, new_target)
        end

        if @params.key?(:current_mastery_level) &&
             new_current < (cm.current_mastery_level || 0)
          cascade_skills(:current_skill_level, :current_skill, new_current)
        end

        if @params.key?(:target_mastery_level) &&
             new_target < (cm.target_mastery_level || 0)
          cascade_skills(:target_skill_level, :target_skill, new_target)
        end

        updates = {}
        updates[:current_mastery_level] = new_current if @params.key?(
          :current_mastery_level
        )
        updates[:target_mastery_level] = new_target if @params.key?(
          :target_mastery_level
        )
        cm.update!(updates) if updates.any?
      end

      ServiceResult.ok(data: cm, warnings: @warnings)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.fail(errors: e.record.errors.full_messages)
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end

    private

    def sync_character_level(char_attr, new_mastery_level)
      char_level = @character.public_send(char_attr) || 0
      return unless new_mastery_level > char_level

      @character.update!(char_attr => new_mastery_level)
      @warnings << "character.#{char_attr} updated to #{new_mastery_level}"
    end

    def cascade_skills(skill_level_attr, skill_method, new_mastery_level)
      char_skills_for_mastery.each do |cs|
        skill = cs.public_send(skill_method)
        next if skill.nil?
        next unless skill.mastery_level_req > new_mastery_level

        new_skill_level =
          cs
            .skill_group
            .skills
            .where("mastery_level_req <= ?", new_mastery_level)
            .order(skill_level: :asc)
            .pick(:skill_level) || 0

        cs.update!(skill_level_attr => new_skill_level)
        @warnings << "skill '#{cs.skill_group.name}' #{skill_level_attr} adjusted to #{new_skill_level}"
      end
    end

    def char_skills_for_mastery
      @character
        .character_skills
        .joins(:skill_group)
        .where(skill_groups: { mastery_id: @mastery.id })
    end
  end
end
