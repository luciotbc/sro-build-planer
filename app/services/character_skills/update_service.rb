module CharacterSkills
  class UpdateService
    include PrerequisiteResolver

    def self.call(character, params) = new(character, params).call

    def initialize(character, params)
      @character = character
      @params = params
      @warnings = []
    end

    def call
      cs =
        CharacterSkill.includes(skill_group: :mastery).find_by(
          character: @character,
          skill_group_id: @params[:skill_group_id]
        )
      return ServiceResult.fail(errors: ["CharacterSkill not found"]) unless cs

      if @params.key?(:character_id)
        return ServiceResult.fail(errors: ["character_id cannot be changed"])
      end

      if @params.key?(:skill_group_id) &&
           @params[:skill_group_id] != cs.skill_group_id
        return(ServiceResult.fail(errors: ["skill_group_id cannot be changed"]))
      end

      sg = cs.skill_group
      new_current = @params[:current_skill_level]
      new_target = @params[:target_skill_level]

      errors =
        (
          if new_current
            validate_level("current_skill_level", new_current, sg)
          else
            []
          end
        ) +
          (
            if new_target
              validate_level("target_skill_level", new_target, sg)
            else
              []
            end
          )
      return ServiceResult.fail(errors:) if errors.any?

      if new_current && new_current < cs.current_skill_level.to_i
        blocking = find_blocking_dependents(sg, new_current, :current)
        if blocking.any?
          return(
            ServiceResult.fail(
              errors: [
                "Cannot decrease current_skill_level: blocked by #{blocking.join(", ")}"
              ]
            )
          )
        end
      end

      if new_target && new_target < cs.target_skill_level.to_i
        blocking = find_blocking_dependents(sg, new_target, :target)
        if blocking.any?
          return(
            ServiceResult.fail(
              errors: [
                "Cannot decrease target_skill_level: blocked by #{blocking.join(", ")}"
              ]
            )
          )
        end
      end

      ApplicationRecord.transaction do
        if new_current && new_current > cs.current_skill_level.to_i
          resolve_prerequisites(sg, Set.new, :current)
          update_mastery(sg, new_current, :current)
        end

        if new_target && new_target > cs.target_skill_level.to_i
          resolve_prerequisites(sg, Set.new, :target)
          update_mastery(sg, new_target, :target)
        end

        updates = {}
        updates[:current_skill_level] = new_current if new_current
        updates[:target_skill_level] = new_target if new_target
        cs.update!(updates) if updates.any?
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
      errors << I18n.t("errors.skill_level.below_zero", attr:) if value < 0
      if sg.max_skill_level && value > sg.max_skill_level
        errors << I18n.t(
          "errors.skill_level.above_max",
          attr:,
          max: sg.max_skill_level
        )
      end
      errors
    end
  end
end
