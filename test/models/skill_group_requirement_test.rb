require "test_helper"

class SkillGroupRequirementTest < ActiveSupport::TestCase
  let(:mastery) { create(:mastery) }
  let(:sg_a) { create(:skill_group, mastery:) }
  let(:sg_b) { create(:skill_group, mastery:) }
  let(:sg_c) { create(:skill_group, mastery:) }
  let(:requirement) do
    create(:skill_group_requirement, skill_group: sg_b, required_group: sg_a)
  end

  it "valid with skill_group and required_group" do
    req = SkillGroupRequirement.new(skill_group: sg_a, required_group: sg_b)

    assert req.valid?
  end

  it "invalid without skill_group" do
    req = SkillGroupRequirement.new(required_group: sg_a)

    assert_not req.valid?
    assert_includes req.errors[:skill_group], "must exist"
  end

  it "invalid without required_group" do
    req = SkillGroupRequirement.new(skill_group: sg_a)

    assert_not req.valid?
    assert_includes req.errors[:required_group], "must exist"
  end

  it "belongs_to skill_group association" do
    assert_equal sg_b, requirement.skill_group
  end

  it "belongs_to required_group resolves to a SkillGroup" do
    assert_instance_of SkillGroup, requirement.required_group
    assert_equal sg_a, requirement.required_group
  end
end
