module CharacterSkills
  module PrerequisiteResolver
    private

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
            @warnings << I18n.t(
              "warnings.prerequisite_level_updated",
              name: required_group.name,
              level: required_level
            )
            resolve_prerequisites(required_group, visited)
          end
        end
    end
  end
end
