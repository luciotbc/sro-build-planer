module CharacterSkills
  class AddService
    include PrerequisiteResolver

    def self.call(character, params) = new(character, params).call

    def initialize(character, params)
      @character = character
      @params = params
      @warnings = []
    end

    def call
      sg =
        SkillGroup.includes(mastery: :race).find_by(
          id: @params[:skill_group_id]
        )
      return ServiceResult.fail(errors: ["SkillGroup must exist"]) unless sg

      unless sg.mastery.race_id == @character.race_id
        return(
          ServiceResult.fail(
            errors: ["SkillGroup race does not match character race"]
          )
        )
      end

      if CharacterSkill.exists?(character: @character, skill_group: sg)
        return(
          ServiceResult.fail(
            errors: ["Skill has already been added to this character"]
          )
        )
      end

      current_level = @params[:current_skill_level]
      if current_level.nil?
        return ServiceResult.fail(errors: ["current_skill_level is required"])
      end

      target_level = @params.fetch(:target_skill_level, 0)

      errors =
        validate_level("current_skill_level", current_level, sg) +
          validate_level("target_skill_level", target_level, sg)
      return ServiceResult.fail(errors:) if errors.any?

      cs = nil
      ApplicationRecord.transaction do
        if current_level > 0
          resolve_prerequisites(sg, Set.new, :current)
          update_mastery(sg, current_level, :current)
        end
        if target_level > 0
          resolve_prerequisites(sg, Set.new, :target)
          update_mastery(sg, target_level, :target)
        end
        cs =
          CharacterSkill.create!(
            character: @character,
            skill_group: sg,
            current_skill_level: current_level,
            target_skill_level: target_level
          )
      end

      ServiceResult.ok(data: cs, warnings: @warnings)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.fail(errors: e.record.errors.full_messages)
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end

    private

    def validate_level(attr, value, sg)
      errors = []
      errors << "#{attr} must be >= 0" if value < 0
      if sg.max_skill_level && value > sg.max_skill_level
        errors << "#{attr} must be <= #{sg.max_skill_level}"
      end
      errors
    end
  end
end
