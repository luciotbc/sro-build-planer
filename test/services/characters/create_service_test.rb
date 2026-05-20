require "test_helper"

class Characters::CreateServiceTest < ActiveSupport::TestCase
  test "creates a character with required fields" do
    result =
      Characters::CreateService.call(name: "Hero", race_id: races(:chinese).id)

    assert result.success?
    assert_instance_of Character, result.data
    assert_equal "Hero", result.data.name
    assert_equal races(:chinese).id, result.data.race_id
  end

  test "sets current_level and target_level to 0 by default" do
    result =
      Characters::CreateService.call(name: "Hero", race_id: races(:chinese).id)

    assert result.success?
    assert_equal 0, result.data.current_level
    assert_equal 0, result.data.target_level
  end

  test "accepts optional current_level and target_level" do
    result =
      Characters::CreateService.call(
        name: "Hero",
        race_id: races(:chinese).id,
        current_level: 30,
        target_level: 80
      )

    assert result.success?
    assert_equal 30, result.data.current_level
    assert_equal 80, result.data.target_level
  end

  test "fails without name" do
    result = Characters::CreateService.call(race_id: races(:chinese).id)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Name") }
  end

  test "fails with blank name" do
    result =
      Characters::CreateService.call(name: "", race_id: races(:chinese).id)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Name") }
  end

  test "fails with non-existent race_id" do
    result = Characters::CreateService.call(name: "Hero", race_id: 0)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Race") }
  end

  test "fails with current_level above MAX_LEVEL" do
    result =
      Characters::CreateService.call(
        name: "Hero",
        race_id: races(:chinese).id,
        current_level: Character::MAX_LEVEL + 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Current level") }
  end

  test "fails with negative target_level" do
    result =
      Characters::CreateService.call(
        name: "Hero",
        race_id: races(:chinese).id,
        target_level: -1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Target level") }
  end

  test "target_level can be lower than current_level" do
    result =
      Characters::CreateService.call(
        name: "Hero",
        race_id: races(:chinese).id,
        current_level: 80,
        target_level: 30
      )

    assert result.success?
  end

  test "returns errors array on failure" do
    result = Characters::CreateService.call(race_id: races(:chinese).id)

    assert_instance_of Array, result.errors
    assert_empty result.warnings
  end

  test "persists the character to the database" do
    assert_difference "Character.count", 1 do
      Characters::CreateService.call(
        name: "Persisted",
        race_id: races(:chinese).id
      )
    end
  end
end
