require "test_helper"

class Users::RegisterServiceTest < ActiveSupport::TestCase
  let(:valid_params) do
    {
      email_address: "new@example.com",
      password: "Password1",
      password_confirmation: "Password1",
      email_opt_in: true
    }
  end

  it "creates a user with the given attributes" do
    result = nil
    assert_difference "User.count", 1 do
      result = Users::RegisterService.call(valid_params)
    end

    assert result.success?
    assert_instance_of User, result.data
    assert_equal "new@example.com", result.data.email_address
    assert result.data.email_opt_in
    assert_not result.data.email_confirmed?
  end

  it "enqueues a confirmation email to the new user" do
    assert_enqueued_emails 1 do
      Users::RegisterService.call(valid_params)
    end
    assert_enqueued_with(
      job: ActionMailer::MailDeliveryJob,
      args: [
        "UsersMailer",
        "email_confirmation",
        "deliver_now",
        { args: [User.find_by(email_address: "new@example.com")] }
      ]
    )
  end

  it "fails with a malformed email" do
    result =
      Users::RegisterService.call(valid_params.merge(email_address: "nope"))

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Email") }
  end

  it "fails with a weak password" do
    result =
      Users::RegisterService.call(
        valid_params.merge(password: "weak", password_confirmation: "weak")
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Password") }
  end

  it "fails when the confirmation does not match" do
    result =
      Users::RegisterService.call(
        valid_params.merge(password_confirmation: "Different1")
      )

    assert_not result.success?
  end

  it "does not enqueue email on failure" do
    assert_no_enqueued_emails do
      Users::RegisterService.call(valid_params.merge(email_address: "nope"))
    end
  end

  it "defaults email_opt_in to false when omitted" do
    result = Users::RegisterService.call(valid_params.except(:email_opt_in))

    assert result.success?
    assert_not result.data.email_opt_in
  end
end
