require "test_helper"

class Users::DeleteAccountServiceTest < ActiveSupport::TestCase
  setup { @user = create(:user, :confirmed) }

  test "wrong confirmation deletes nothing" do
    result = Users::DeleteAccountService.call(user: @user, confirmation: "nope")

    assert_not result.success?
    assert result.errors.any?
    assert User.exists?(@user.id)
  end

  test "typed DELETE destroys the user and every dependent record" do
    @user.sessions.create!(user_agent: "a", ip_address: "1.1.1.1")
    race = create(:race, name: "Chinese")
    mastery = create(:mastery, race: race)
    group = create(:skill_group, mastery: mastery)
    character = create(:character, user: @user, race: race)
    create(:character_mastery, character: character, mastery: mastery)
    create(:character_skill, character: character, skill_group: group)

    result =
      Users::DeleteAccountService.call(user: @user, confirmation: "DELETE")

    assert result.success?
    assert_not User.exists?(@user.id)
    assert_not Session.exists?(user_id: @user.id)
    assert_not Character.exists?(character.id)
    assert_not CharacterMastery.exists?(character_id: character.id)
    assert_not CharacterSkill.exists?(character_id: character.id)
  end
end
