module CharacterSkills
  class AddService
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
      ActiveRecord::Base.transaction do
        resolve_prerequisites(sg, Set.new) if current_level > 0
        ensure_mastery(sg, current_level, target_level)
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
            resolve_prerequisites(required_group, visited)
            add_prerequisite(required_group, required_level)
          elsif existing.current_skill_level.to_i < required_level
            existing.update!(current_skill_level: required_level)
            @warnings << "prerequisite '#{required_group.name}' current_skill_level atualizado para #{required_level}"
          end
        end
    end

    def add_prerequisite(skill_group, level)
      ensure_mastery(skill_group, level, level)
      CharacterSkill.create!(
        character: @character,
        skill_group: skill_group,
        current_skill_level: level,
        target_skill_level: level
      )
      @warnings << "prerequisite '#{skill_group.name}' adicionado automaticamente"
    end

    def ensure_mastery(skill_group, current_level, target_level)
      mastery = skill_group.mastery
      current_req =
        skill_group.skill_at_level(current_level)&.mastery_level_req.to_i
      target_req =
        skill_group.skill_at_level(target_level)&.mastery_level_req.to_i

      cm = CharacterMastery.find_by(character: @character, mastery:)

      if cm.nil?
        CharacterMastery.create!(
          character: @character,
          mastery:,
          current_mastery_level: current_req,
          target_mastery_level: target_req
        )
        @warnings << "CharacterMastery '#{mastery.name}' criada automaticamente"
        sync_character_level(:current_level, current_req)
        sync_character_level(:target_level, target_req)
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
