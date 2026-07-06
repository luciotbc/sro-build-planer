module CharacterSkills
  module PrerequisiteResolver
    private

    def resolve_prerequisites(skill_group, visited, side)
      return if visited.include?(skill_group.id)
      visited.add(skill_group.id)

      skill_level_attr = :"#{side}_skill_level"

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
            resolve_prerequisites(required_group, visited, side)
            unless already_visited
              add_prerequisite(required_group, required_level, side)
            end
          elsif existing.public_send(skill_level_attr).to_i < required_level
            existing.update!(skill_level_attr => required_level)
            @warnings << I18n.t(
              "warnings.prerequisite_level_updated.#{side}",
              name: required_group.name,
              level: required_level
            )
            resolve_prerequisites(required_group, visited, side)
          end
        end
    end

    def add_prerequisite(skill_group, level, side)
      update_mastery(skill_group, level, side)
      CharacterSkill.create!(
        character: @character,
        skill_group: skill_group,
        current_skill_level: 0,
        target_skill_level: 0,
        "#{side}_skill_level": level
      )
      @warnings << I18n.t("warnings.prerequisite_added", name: skill_group.name)
    end

    def update_mastery(skill_group, level, side)
      mastery = skill_group.mastery
      req = skill_group.skill_at_level(level)&.mastery_level_req.to_i
      mastery_level_attr = :"#{side}_mastery_level"

      cm = CharacterMastery.find_by(character: @character, mastery:)

      if cm.nil?
        CharacterMastery.create!(
          character: @character,
          mastery:,
          current_mastery_level: 0,
          target_mastery_level: 0,
          mastery_level_attr => req
        )
        @warnings << I18n.t(
          "warnings.character_mastery_created",
          name: mastery.name
        )
      elsif cm.public_send(mastery_level_attr).to_i < req
        cm.update!(mastery_level_attr => req)
        @warnings << I18n.t(
          "warnings.character_mastery_level_updated.#{side}",
          name: mastery.name,
          level: req
        )
      end
    end

    def find_blocking_dependents(skill_group, new_level, side)
      skill_level_attr = :"#{side}_skill_level"

      reqs =
        SkillGroupRequirement
          .includes(:skill_group)
          .where(required_group: skill_group)
          .where("required_skill_level > ?", new_level)

      return [] if reqs.empty?

      cs_by_sg =
        @character
          .character_skills
          .where(skill_group_id: reqs.map(&:skill_group_id))
          .index_by(&:skill_group_id)

      reqs.filter_map do |req|
        dep_cs = cs_by_sg[req.skill_group_id]
        next unless dep_cs
        unless dep_cs.public_send(skill_level_attr).to_i >=
                 req.required_skill_level.to_i
          next
        end
        req.skill_group.name
      end
    end
  end
end
