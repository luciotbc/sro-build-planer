require "test_helper"

class CharacterTest < ActiveSupport::TestCase
  let(:user) { create(:user) }
  let(:race) { create(:race) }

  # ---------- basic validity --------------------------------------------------

  it "valid with name, race, user, and server_level_cap" do
    assert Character.new(
             name: "Test Character",
             race:,
             user:,
             server_level_cap: 110
           ).valid?
  end

  it "invalid without name" do
    character = Character.new(race:, user:, server_level_cap: 110)

    assert_not character.valid?
    assert_includes character.errors[:name], "can't be blank"
  end

  it "localizes the name-blank error message per locale (rails-i18n)" do
    character = Character.new(race:, user:, server_level_cap: 110)
    character.valid?

    I18n.with_locale(:"pt-BR") do
      character.valid?
      assert_equal "Nome não pode ficar em branco",
                   character.errors.full_messages_for(:name).first
    end
  end

  it "invalid without race" do
    character =
      Character.new(name: "Test Character", user:, server_level_cap: 110)

    assert_not character.valid?
    assert_includes character.errors[:race], "must exist"
  end

  it "invalid without user" do
    character =
      Character.new(name: "Test Character", race:, server_level_cap: 110)

    assert_not character.valid?
    assert_includes character.errors[:user], "must exist"
  end

  it "invalid with blank name" do
    character = Character.new(name: "", race:, user:, server_level_cap: 110)

    assert_not character.valid?
    assert_includes character.errors[:name], "can't be blank"
  end

  it "invalid with nonexistent race_id" do
    character =
      Character.new(name: "Test", race_id: 0, user:, server_level_cap: 110)

    assert_not character.valid?
    assert_includes character.errors[:race], "must exist"
  end

  # ---------- associations ----------------------------------------------------

  it "belongs_to race association" do
    character = create(:character, race:, user:)

    assert_equal race, character.race
  end

  it "belongs_to user association" do
    character = create(:character, race:, user:)

    assert_equal user, character.user
  end

  it "has_many character_masteries" do
    assert_respond_to create(:character, race:, user:), :character_masteries
  end

  it "has_many character_skills" do
    assert_respond_to create(:character, race:, user:), :character_skills
  end

  # ---------- server_level_cap ------------------------------------------------

  it "valid with server_level_cap of 90" do
    assert Character.new(
             name: "Test",
             race:,
             user:,
             server_level_cap: 90
           ).valid?
  end

  it "valid with server_level_cap of 130" do
    assert Character.new(
             name: "Test",
             race:,
             user:,
             server_level_cap: 130
           ).valid?
  end

  [90, 100, 110, 120, 130].each do |cap|
    it "valid with server_level_cap #{cap}" do
      assert Character.new(
               name: "Test",
               race:,
               user:,
               server_level_cap: cap
             ).valid?
    end
  end

  it "invalid with server_level_cap not in allowed set" do
    character = Character.new(name: "Test", race:, user:, server_level_cap: 95)

    assert_not character.valid?
    assert character.errors[:server_level_cap].any?
  end

  it "invalid without server_level_cap" do
    character = Character.new(name: "Test", race:, user:, server_level_cap: nil)

    assert_not character.valid?
    assert character.errors[:server_level_cap].any?
  end

  # ---------- MAX_LEVEL constant ----------------------------------------------

  it "MAX_LEVEL constant is 150" do
    assert_equal 150, Character::MAX_LEVEL
  end

  # ---------- level caches (current_level / target_level) --------------------

  it "current_level and target_level default to nil on new character" do
    character = create(:character, race:, user:)

    assert_nil character.current_level
    assert_nil character.target_level
  end

  it "recompute_levels! sets current_level from max of mastery current levels" do
    character = create(:character, race:, user:)
    mastery_a = create(:mastery, race:)
    mastery_b = create(:mastery, race:)
    create(
      :character_mastery,
      character:,
      mastery: mastery_a,
      current_mastery_level: 40,
      target_mastery_level: 0
    )
    create(
      :character_mastery,
      character:,
      mastery: mastery_b,
      current_mastery_level: 60,
      target_mastery_level: 0
    )

    assert_equal 60, character.reload.current_level
  end

  it "recompute_levels! sets target_level from max of mastery target levels" do
    character = create(:character, race:, user:)
    mastery = create(:mastery, race:)
    create(
      :character_mastery,
      character:,
      mastery:,
      current_mastery_level: 0,
      target_mastery_level: 80
    )

    assert_equal 80, character.reload.target_level
  end

  it "recompute_levels! sets levels to 0 when no masteries remain" do
    character = create(:character, race:, user:)
    mastery = create(:mastery, race:)
    cm =
      create(
        :character_mastery,
        character:,
        mastery:,
        current_mastery_level: 50,
        target_mastery_level: 70
      )
    cm.destroy!

    assert_equal 0, character.reload.current_level
    assert_equal 0, character.reload.target_level
  end

  # ---------- share token -----------------------------------------------------

  it "generates a short base58 share_token on create" do
    character = create(:character, race:, user:)
    # has_secure_token(length: 10) → 10 base58 chars for a compact share URL.
    assert_match(/\A[1-9A-HJ-NP-Za-km-z]{10}\z/, character.share_token)
  end

  it "keeps the share_token stable across updates" do
    character = create(:character, race:, user:)
    token = character.share_token
    character.update!(name: "Renamed")
    assert_equal token, character.reload.share_token
  end

  it "gives each character a distinct share_token" do
    a = create(:character, race:, user:)
    b = create(:character, race:, user:)
    refute_equal a.share_token, b.share_token
  end
end
