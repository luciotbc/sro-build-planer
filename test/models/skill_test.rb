require "test_helper"

class SkillTest < ActiveSupport::TestCase
  let(:skill_group) { create(:skill_group) }
  let(:existing_skill) { create(:skill, skill_group:, skill_level: 1) }

  it "valid with all required attributes" do
    skill =
      Skill.new(
        external_id: 2000,
        external_skill_code: "TEST_SKILL_001",
        skill_group:,
        skill_level: 1
      )

    assert skill.valid?
  end

  it "invalid without external_id" do
    skill =
      Skill.new(
        external_skill_code: "TEST_SKILL_001",
        skill_group:,
        skill_level: 1
      )

    assert_not skill.valid?
    assert_includes skill.errors[:external_id], "can't be blank"
  end

  it "invalid with duplicate external_id" do
    skill =
      Skill.new(
        external_id: existing_skill.external_id,
        external_skill_code: "NEW_SKILL_001",
        skill_group:,
        skill_level: 1
      )

    assert_not skill.valid?
    assert_includes skill.errors[:external_id], "has already been taken"
  end

  it "invalid without external_skill_code" do
    skill = Skill.new(external_id: 2001, skill_group:, skill_level: 1)

    assert_not skill.valid?
    assert_includes skill.errors[:external_skill_code], "can't be blank"
  end

  it "invalid with duplicate external_skill_code" do
    skill =
      Skill.new(
        external_id: 2002,
        external_skill_code: existing_skill.external_skill_code,
        skill_group:,
        skill_level: 1
      )

    assert_not skill.valid?
    assert_includes skill.errors[:external_skill_code], "has already been taken"
  end

  it "invalid without skill_level" do
    skill =
      Skill.new(
        external_id: 2003,
        external_skill_code: "TEST_SKILL_003",
        skill_group:
      )

    assert_not skill.valid?
    assert_includes skill.errors[:skill_level], "can't be blank"
  end

  it "invalid without skill_group" do
    skill =
      Skill.new(
        external_id: 2005,
        external_skill_code: "TEST_SKILL_005",
        skill_level: 1
      )

    assert_not skill.valid?
  end

  it "belongs_to skill_group association" do
    assert_equal skill_group, existing_skill.skill_group
  end

  it "database rejects null external_id" do
    skill =
      Skill.new(
        external_id: nil,
        external_skill_code: "TEST_SKILL_006",
        skill_group:,
        skill_level: 1
      )

    assert_raises(ActiveRecord::NotNullViolation) do
      skill.save!(validate: false)
    end
  end

  it "database rejects null external_skill_code" do
    skill =
      Skill.new(
        external_id: 2006,
        external_skill_code: nil,
        skill_group:,
        skill_level: 1
      )

    assert_raises(ActiveRecord::NotNullViolation) do
      skill.save!(validate: false)
    end
  end

  it "database rejects null skill_level" do
    skill =
      Skill.new(
        external_id: 2007,
        external_skill_code: "TEST_SKILL_007",
        skill_group:,
        skill_level: nil
      )

    assert_raises(ActiveRecord::NotNullViolation) do
      skill.save!(validate: false)
    end
  end

  it "sp_cost and mastery_level_req are nullable" do
    skill =
      Skill.new(
        external_id: 2009,
        external_skill_code: "TEST_SKILL_009",
        skill_group:,
        skill_level: 1,
        sp_cost: nil,
        mastery_level_req: nil
      )

    assert skill.valid?
  end
end
