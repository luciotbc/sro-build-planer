require "test_helper"

class Users::UpdatePasswordServiceTest < ActiveSupport::TestCase
  setup { @user = create(:user, :confirmed) }

  test "changes the password and destroys other sessions" do
    current = @user.sessions.create!(user_agent: "a", ip_address: "1.1.1.1")
    other = @user.sessions.create!(user_agent: "b", ip_address: "2.2.2.2")

    result =
      Users::UpdatePasswordService.call(
        user: @user,
        current_password: "Password1",
        password: "NewPassword2",
        password_confirmation: "NewPassword2",
        current_session: current
      )

    assert result.success?
    assert @user.reload.authenticate("NewPassword2")
    assert Session.exists?(current.id)
    assert_not Session.exists?(other.id)
  end

  test "rejects a wrong current password" do
    result =
      Users::UpdatePasswordService.call(
        user: @user,
        current_password: "WrongPass9",
        password: "NewPassword2",
        password_confirmation: "NewPassword2",
        current_session: nil
      )

    assert_not result.success?
    assert result.errors.any?
    assert @user.reload.authenticate("Password1")
  end

  test "rejects a new password violating the model rules" do
    result =
      Users::UpdatePasswordService.call(
        user: @user,
        current_password: "Password1",
        password: "weak",
        password_confirmation: "weak",
        current_session: nil
      )

    assert_not result.success?
    assert @user.reload.authenticate("Password1")
  end

  test "rejects a mismatched confirmation" do
    result =
      Users::UpdatePasswordService.call(
        user: @user,
        current_password: "Password1",
        password: "NewPassword2",
        password_confirmation: "Different3",
        current_session: nil
      )

    assert_not result.success?
    assert @user.reload.authenticate("Password1")
  end
end
