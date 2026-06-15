module CharacterSkills
  class MaxAllService
    def self.call(character, groups, kind:) = new(character, groups, kind:).call

    def initialize(character, groups, kind:)
      @character = character
      @groups = groups
      @kind = kind
    end

    def call
      results = []
      ApplicationRecord.transaction do
        results = @groups.map { |group| apply(group) }
        raise ActiveRecord::Rollback if results.any? { |r| !r.success? }
      end
      failed = results.reject(&:success?)
      if failed.any?
        ServiceResult.fail(errors: failed.flat_map(&:errors))
      else
        ServiceResult.ok
      end
    end

    private

    def apply(group)
      level = group.max_skill_level.to_i
      exists = @character.character_skills.exists?(skill_group_id: group.id)
      if exists
        level_attr =
          @kind == :current ? :current_skill_level : :target_skill_level
        CharacterSkills::UpdateService.call(
          @character,
          :skill_group_id => group.id,
          level_attr => level
        )
      else
        CharacterSkills::AddService.call(
          @character,
          skill_group_id: group.id,
          current_skill_level: @kind == :current ? level : 0,
          target_skill_level: level
        )
      end
    end
  end
end
