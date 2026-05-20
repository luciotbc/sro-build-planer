module CharacterSkills
  class UpdateService
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
      SkillGroupRequirement
        .includes(:skill_group)
        .where(required_group: skill_group)
        .where("required_skill_level > ?", new_current_level)
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

    def resolve_prerequisites(skill_group, visited)
      return if visited.include?(skill_group.id)
      visited.add(skill_group.id)

      skill_group
        .skill_group_requirements
        .includes(required_group: :mastery)
        .each do |req|
          required_group = req.required_group
          required_level = req.required_skill_level.to_i
          next if required_level == 0

          existing =
            @character.character_skills.find_by(skill_group: required_group)

          if existing.nil?
            already_visited = visited.include?(required_group.id)
            resolve_prerequisites(required_group, visited)
            unless already_visited
              add_prerequisite(required_group, required_level)
            end
          elsif existing.current_skill_level.to_i < required_level
            existing.update!(current_skill_level: required_level)
            @warnings << "prerequisite '#{required_group.name}' current_skill_level atualizado para #{required_level}"
            resolve_prerequisites(required_group, visited)
          end
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
      @warnings << "prerequisite '#{skill_group.name}' adicionado automaticamente"
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
        @warnings << "CharacterMastery '#{mastery.name}' criada automaticamente"
        sync_character_level(:current_level, current_req)
      elsif cm.current_mastery_level.to_i < current_req
        cm.update!(current_mastery_level: current_req)
        @warnings << "CharacterMastery '#{mastery.name}' current_mastery_level atualizado para #{current_req}"
        sync_character_level(:current_level, current_req)
      end
    end

    def sync_character_level(attr, mastery_level)
      char_level = @character.public_send(attr).to_i
      return unless mastery_level > char_level

      @character.update!(attr => mastery_level)
      @warnings << "character.#{attr} atualizado para #{mastery_level}"
    end
  end
end
