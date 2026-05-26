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
        blocking = find_blocking_dependents(sg, new_current)
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

      ActiveRecord::Base.transaction do
        if new_current && new_current > cs.current_skill_level.to_i
          resolve_prerequisites(sg, Set.new)
          update_mastery(sg, new_current)
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
      errors << "#{attr} must be >= 0" if value < 0
      if sg.max_skill_level && value > sg.max_skill_level
        errors << "#{attr} must be <= #{sg.max_skill_level}"
      end
      errors
    end

    def find_blocking_dependents(skill_group, new_current_level)
      reqs =
        SkillGroupRequirement
          .includes(:skill_group)
          .where(required_group: skill_group)
          .where("required_skill_level > ?", new_current_level)

      return [] if reqs.empty?

      cs_by_sg =
        @character
          .character_skills
          .where(skill_group_id: reqs.map(&:skill_group_id))
          .index_by(&:skill_group_id)

      reqs.filter_map do |req|
        dep_cs = cs_by_sg[req.skill_group_id]
        next unless dep_cs
        unless dep_cs.current_skill_level.to_i >= req.required_skill_level.to_i
          next
        end

        req.skill_group.name
      end
    end

    def add_prerequisite(skill_group, level)
      update_mastery(skill_group, level)
      CharacterSkill.create!(
        character: @character,
        skill_group: skill_group,
        current_skill_level: level,
        target_skill_level: level
      )
      @warnings << "prerequisite '#{skill_group.name}' added automatically"
    end

    def update_mastery(skill_group, current_level)
      mastery = skill_group.mastery
      current_req =
        skill_group.skill_at_level(current_level)&.mastery_level_req.to_i

      cm = CharacterMastery.find_by(character: @character, mastery:)

      if cm.nil?
        CharacterMastery.create!(
          character: @character,
          mastery:,
          current_mastery_level: current_req,
          target_mastery_level: 0
        )
        @warnings << "CharacterMastery '#{mastery.name}' created automatically"
        sync_character_level(:current_level, current_req)
      elsif cm.current_mastery_level.to_i < current_req
        cm.update!(current_mastery_level: current_req)
        @warnings << "CharacterMastery '#{mastery.name}' current_mastery_level updated to #{current_req}"
        sync_character_level(:current_level, current_req)
      end
    end
  end
end
