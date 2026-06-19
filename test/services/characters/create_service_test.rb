require "test_helper"

class Characters::CreateServiceTest < ActiveSupport::TestCase
  let(:user) { create(:user) }
  let(:race) { create(:race) }

  it "creates a character with required fields" do
    result =
      Characters::CreateService.call(name: "Hero", race_id: race.id, user:)

    assert result.success?
    assert_instance_of Character, result.data
    assert_equal "Hero", result.data.name
    assert_equal race.id, result.data.race_id
    assert_equal user, result.data.user
  end

  it "sets server_level_cap to 110 by default" do
    result =
      Characters::CreateService.call(name: "Hero", race_id: race.id, user:)

    assert result.success?
    assert_equal 110, result.data.server_level_cap
  end

  it "accepts optional server_level_cap" do
    result =
      Characters::CreateService.call(
        name: "Hero",
        race_id: race.id,
        user:,
        server_level_cap: 130
      )

    assert result.success?
    assert_equal 130, result.data.server_level_cap
  end

  it "fails without name" do
    result = Characters::CreateService.call(race_id: race.id, user:)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Name") }
  end

  it "fails with blank name" do
    result = Characters::CreateService.call(name: "", race_id: race.id, user:)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Name") }
  end

  it "fails with non-existent race_id" do
    result = Characters::CreateService.call(name: "Hero", race_id: 0, user:)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Race") }
  end

  it "fails without user" do
    result = Characters::CreateService.call(name: "Hero", race_id: race.id)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("User") }
  end

  it "fails with invalid server_level_cap" do
    result =
      Characters::CreateService.call(
        name: "Hero",
        race_id: race.id,
        user:,
        server_level_cap: 95
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Server level cap") }
  end

  it "returns errors array on failure" do
    result = Characters::CreateService.call(race_id: race.id, user:)

    assert_instance_of Array, result.errors
    assert_empty result.warnings
  end

  it "persists the character to the database" do
    assert_difference "Character.count", 1 do
      Characters::CreateService.call(name: "Persisted", race_id: race.id, user:)
    end
  end
end
