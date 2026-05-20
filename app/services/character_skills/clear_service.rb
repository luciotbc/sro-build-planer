module CharacterSkills
  class ClearService
    VALID_FIELDS = %i[current target both].freeze

    def self.call(character, params) = new(character, params).call

    def initialize(character, params)
      @character = character
      @params = params
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

      if field == :current || field == :both
        blocking = find_blocking_dependents(cs.skill_group)
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

      updates = {}
      updates[:current_skill_level] = 0 if field == :current || field == :both
      updates[:target_skill_level] = 0 if field == :target || field == :both
      cs.update!(updates)

      ServiceResult.ok(data: cs)
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end

    private

    def find_blocking_dependents(skill_group)
      SkillGroupRequirement
        .includes(:skill_group)
        .where(required_group: skill_group)
        .filter_map do |req|
          dep_cs =
            @character.character_skills.find_by(skill_group: req.skill_group)
          next unless dep_cs
          unless dep_cs.current_skill_level.to_i >=
                   req.required_skill_level.to_i
            next
          end

          req.skill_group.name
        end
    end
  end
end
