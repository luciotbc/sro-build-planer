require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  it "is invalid without email_address" do
    user = User.new(password: "x")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  it "is invalid with a duplicate email_address" do
    create(:user, email_address: "taken@example.com")
    duplicate = User.new(email_address: "taken@example.com", password: "x")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  it "uniqueness check is case-insensitive" do
    create(:user, email_address: "a@b.com")
    duplicate = User.new(email_address: "A@B.COM", password: "x")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end
end
