module CharacterSkills
  class MaxMasteryService
    include PrerequisiteResolver

    def self.call(character, params) = new(character, params).call

    def initialize(character, params)
      @character = character
      @mastery = params[:mastery]
      @side = params[:side]
      @warnings = []
    end

    def call
      skill_level_attr = :"#{@side}_skill_level"

      ApplicationRecord.transaction do
        @mastery
          .skill_groups
          .includes(:skills, :skill_group_requirements)
          .order(:col_position)
          .each do |sg|
            cap = sg.effective_cap(@character.server_level_cap)
            next if cap == 0

            cs = @character.character_skills.find_by(skill_group: sg)

            if cs.nil?
              resolve_prerequisites(sg, Set.new, @side)
              add_prerequisite(sg, cap, @side)
            elsif cs.public_send(skill_level_attr).to_i < cap
              resolve_prerequisites(sg, Set.new, @side)
              update_mastery(sg, cap, @side)
              cs.update!(skill_level_attr => cap)
            end
          end
      end

      ServiceResult.ok(data: nil, warnings: @warnings)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.fail(errors: e.record.errors.full_messages)
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end
  end
end
