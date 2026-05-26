module CharacterMasteries
  class ClearService
    VALID_FIELDS = %i[current target both].freeze

    def self.call(character, params) = new(character, params).call

    def initialize(character, params)
      @character = character
      @params = params
    end

    def call
      cm =
        CharacterMastery.find_by(
          character: @character,
          mastery_id: @params[:mastery_id]
        )
      unless cm
        return ServiceResult.fail(errors: ["CharacterMastery not found"])
      end

      field = @params[:field]
      unless VALID_FIELDS.include?(field)
        return(
          ServiceResult.fail(
            errors: ["field must be :current, :target, or :both"]
          )
        )
      end

      mastery_updates = {}
      skill_updates = {}

      if field == :current || field == :both
        mastery_updates[:current_mastery_level] = 0
        skill_updates[:current_skill_level] = 0
      end

      if field == :target || field == :both
        mastery_updates[:target_mastery_level] = 0
        skill_updates[:target_skill_level] = 0
      end

      ApplicationRecord.transaction do
        cm.update!(mastery_updates)
        char_skills_for(cm.mastery_id).update_all(skill_updates)
      end

      ServiceResult.ok(data: cm)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.fail(errors: e.record.errors.full_messages)
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end

    private

    def char_skills_for(mastery_id)
      @character
        .character_skills
        .joins(:skill_group)
        .where(skill_groups: { mastery_id: })
    end
  end
end
