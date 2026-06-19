module CharacterSkills
  class ClearService
    include PrerequisiteResolver

    VALID_FIELDS = %i[current target both].freeze

    def self.call(character, params) = new(character, params).call

    def initialize(character, params)
      @character = character
      @params = params
      @warnings = []
    end

    def call
      cs =
        CharacterSkill.includes(:skill_group).find_by(
          character: @character,
          skill_group_id: @params[:skill_group_id]
        )
      return ServiceResult.fail(errors: ["CharacterSkill not found"]) unless cs

      field = @params[:field]
      unless VALID_FIELDS.include?(field)
        return(
          ServiceResult.fail(
            errors: ["field must be :current, :target, or :both"]
          )
        )
      end

      if field.in?(%i[current both])
        blocking = find_blocking_dependents(cs.skill_group, 0, :current)
        if blocking.any?
          return(
            ServiceResult.fail(
              errors: [
                "Cannot clear current_skill_level: blocked by #{blocking.join(", ")}"
              ]
            )
          )
        end
      end

      if field.in?(%i[target both])
        blocking = find_blocking_dependents(cs.skill_group, 0, :target)
        if blocking.any?
          return(
            ServiceResult.fail(
              errors: [
                "Cannot clear target_skill_level: blocked by #{blocking.join(", ")}"
              ]
            )
          )
        end
      end

      updates = {}
      updates[:current_skill_level] = 0 if field.in?(%i[current both])
      updates[:target_skill_level] = 0 if field.in?(%i[target both])

      ApplicationRecord.transaction { cs.update!(updates) }

      ServiceResult.ok(data: cs)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.fail(errors: e.record.errors.full_messages)
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end
  end
end
