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
end
