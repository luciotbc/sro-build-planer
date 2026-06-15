require "test_helper"

class Characters::CreateServiceTest < ActiveSupport::TestCase
  let(:race) { create(:race) }

  it "creates a character with required fields" do
    result = Characters::CreateService.call(name: "Hero", race_id: race.id)

    assert result.success?
    assert_instance_of Character, result.data
    assert_equal "Hero", result.data.name
    assert_equal race.id, result.data.race_id
  end

  it "sets current_level and target_level to 0 by default" do
    result = Characters::CreateService.call(name: "Hero", race_id: race.id)

    assert result.success?
    assert_equal 0, result.data.current_level
    assert_equal 0, result.data.target_level
  end

  it "accepts optional current_level and target_level" do
    result =
      Characters::CreateService.call(
        name: "Hero",
        race_id: race.id,
        current_level: 30,
        target_level: 90
      )

    assert result.success?
    assert_equal 30, result.data.current_level
    assert_equal 90, result.data.target_level
  end

  it "fails without name" do
    result = Characters::CreateService.call(race_id: race.id)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Name") }
  end

  it "fails with blank name" do
    result = Characters::CreateService.call(name: "", race_id: race.id)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Name") }
  end

  it "fails with non-existent race_id" do
    result = Characters::CreateService.call(name: "Hero", race_id: 0)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Race") }
  end

  it "fails with current_level above MAX_LEVEL" do
    result =
      Characters::CreateService.call(
        name: "Hero",
        race_id: race.id,
        current_level: Character::MAX_LEVEL + 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Current level") }
  end

  it "fails with negative target_level" do
    result =
      Characters::CreateService.call(
        name: "Hero",
        race_id: race.id,
        target_level: -1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Target level") }
  end

  it "target_level can be lower than current_level" do
    result =
      Characters::CreateService.call(
        name: "Hero",
        race_id: race.id,
        current_level: 110,
        target_level: 90
      )

    assert result.success?
  end

  it "returns errors array on failure" do
    result = Characters::CreateService.call(race_id: race.id)

    assert_instance_of Array, result.errors
    assert_empty result.warnings
  end

  it "persists the character to the database" do
    assert_difference "Character.count", 1 do
      Characters::CreateService.call(name: "Persisted", race_id: race.id)
    end
  end
  it "assigns the character to the given user" do
    user = create(:user)
    result =
      Characters::CreateService.call(name: "Hero", race_id: race.id, user:)

    assert result.success?
    assert_equal user, result.data.user
  end
end
