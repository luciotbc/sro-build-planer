require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "email_opt_in defaults to false" do
    user = create(:user)
    assert_equal(false, user.email_opt_in)
  end

  test "email_confirmed_at is nil by default" do
    user = create(:user)
    assert_nil(user.email_confirmed_at)
  end

  test "valid with email, password and confirmation" do
    assert build(:user).valid?
  end

  test "invalid without email_address" do
    user = build(:user, email_address: nil)
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "invalid with malformed email_address" do
    user = build(:user, email_address: "not-an-email")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "is invalid"
  end

  test "invalid with duplicate email_address" do
    create(:user, email_address: "dupe@example.com")
    user = build(:user, email_address: "dupe@example.com")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "invalid with password shorter than 8 characters" do
    user = build(:user, password: "Ab1", password_confirmation: "Ab1")
    assert_not user.valid?
    assert_includes user.errors[:password],
                    "is too short (minimum is 8 characters)"
  end

  test "invalid without an uppercase letter and a number" do
    user =
      build(
        :user,
        password: "alllowercase",
        password_confirmation: "alllowercase"
      )
    assert_not user.valid?
    assert_includes user.errors[:password],
                    "must include an uppercase letter and a number"
  end

  test "valid with password meeting complexity rules" do
    assert build(
             :user,
             password: "Secret99",
             password_confirmation: "Secret99"
           ).valid?
  end

  test "email_confirmed? reflects email_confirmed_at" do
    assert_not build(:user).email_confirmed?
    assert build(:user, :confirmed).email_confirmed?
  end

  test "confirm_email! sets email_confirmed_at" do
    user = create(:user)
    freeze_time do
      user.confirm_email!
      assert_equal Time.current, user.reload.email_confirmed_at
    end
  end

  test "round-trips an email_confirmation token" do
    user = create(:user)
    token = user.generate_token_for(:email_confirmation)
    assert_equal user, User.find_by_token_for(:email_confirmation, token)
  end

  test "email_confirmation token is single-use once the account is confirmed" do
    user = create(:user)
    token = user.generate_token_for(:email_confirmation)
    user.confirm_email!

    assert_nil User.find_by_token_for(:email_confirmation, token)
  end

  test "has_many characters" do
    user = create(:user)
    race = create(:race)
    create(:character, user:, race:)
    create(:character, user:, race:)

    assert_equal 2, user.characters.count
  end

  test "destroying user destroys associated characters" do
    user = create(:user)
    race = create(:race)
    create(:character, user:, race:)

    assert_difference "Character.count", -1 do
      user.destroy!
    end
  end
end
