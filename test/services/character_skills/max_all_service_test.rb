require "test_helper"

class CharacterSkills::MaxAllServiceTest < ActiveSupport::TestCase
  before do
    @race = create(:race)
    @other_race = create(:race)
    @mastery = create(:mastery, race: @race)
    @other_mastery = create(:mastery, race: @other_race)
    @group_a =
      create(
        :skill_group,
        mastery: @mastery,
        name: "Group A",
        max_skill_level: 3
      )
    @group_b =
      create(
        :skill_group,
        mastery: @mastery,
        name: "Group B",
        max_skill_level: 2
      )
    # group_c belongs to a different race -- AddService will reject it with a race error
    @group_c =
      create(
        :skill_group,
        mastery: @other_mastery,
        name: "Group C",
        max_skill_level: 1
      )
    create(:skill, skill_group: @group_a, skill_level: 1, mastery_level_req: 1)
    create(:skill, skill_group: @group_a, skill_level: 2, mastery_level_req: 2)
    create(:skill, skill_group: @group_a, skill_level: 3, mastery_level_req: 3)
    create(:skill, skill_group: @group_b, skill_level: 1, mastery_level_req: 1)
    create(:skill, skill_group: @group_b, skill_level: 2, mastery_level_req: 2)
    create(:skill, skill_group: @group_c, skill_level: 1, mastery_level_req: 1)
    @char = create(:character, race: @race, current_level: 10, target_level: 10)
  end

  # --------- success path ---------------------------------------------------

  it "creates CharacterSkills at max level for all groups (target kind)" do
    result =
      CharacterSkills::MaxAllService.call(
        @char,
        [@group_a, @group_b],
        kind: :future
      )

    assert result.success?
    cs_a = CharacterSkill.find_by(character: @char, skill_group: @group_a)
    cs_b = CharacterSkill.find_by(character: @char, skill_group: @group_b)
    assert_not_nil cs_a
    assert_not_nil cs_b
    assert_equal 3, cs_a.target_skill_level
    assert_equal 2, cs_b.target_skill_level
  end

  it "sets current_skill_level when kind is :current" do
    result =
      CharacterSkills::MaxAllService.call(@char, [@group_a], kind: :current)

    assert result.success?
    cs_a = CharacterSkill.find_by(character: @char, skill_group: @group_a)
    assert_equal 3, cs_a.current_skill_level
  end

  it "updates existing CharacterSkills to max level" do
    create(
      :character_skill,
      character: @char,
      skill_group: @group_a,
      current_skill_level: 1,
      target_skill_level: 1
    )

    result =
      CharacterSkills::MaxAllService.call(@char, [@group_a], kind: :future)

    assert result.success?
    cs_a = CharacterSkill.find_by(character: @char, skill_group: @group_a)
    assert_equal 3, cs_a.target_skill_level
  end

  it "returns ServiceResult.ok with no groups" do
    result = CharacterSkills::MaxAllService.call(@char, [], kind: :future)
    assert result.success?
  end

  # --------- rollback on partial failure ------------------------------------

  it "rolls back all changes when one group fails and returns aggregated errors" do
    # group_c belongs to @other_race; AddService rejects it with a race mismatch
    # error, triggering a real ActiveRecord::Rollback inside the transaction.
    count_before = CharacterSkill.count

    result =
      CharacterSkills::MaxAllService.call(
        @char,
        [@group_a, @group_c],
        kind: :future
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("race") }
    assert_equal(
      count_before,
      CharacterSkill.count,
      "transaction must have rolled back all inserts"
    )
  end

  it "returns all error messages from failed groups" do
    result =
      CharacterSkills::MaxAllService.call(
        @char,
        [@group_a, @group_c],
        kind: :future
      )

    assert result.errors.any?
  end
end
