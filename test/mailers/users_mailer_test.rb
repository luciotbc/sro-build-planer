require "test_helper"

class UsersMailerTest < ActiveSupport::TestCase
  it "addresses the confirmation email to the user with the right subject" do
    user = create(:user)
    mail = UsersMailer.email_confirmation(user)

    assert_equal [user.email_address], mail.to
    assert_equal "Confirm your email", mail.subject
  end

  it "includes a working confirmation link" do
    user = create(:user)
    mail = UsersMailer.email_confirmation(user)

    %i[html_part text_part].each do |part|
      token =
        mail.public_send(part).body.to_s[%r{email_confirmation/([^"\s]+)}, 1]
      assert token, "expected a confirmation token in the #{part}"
      assert_equal user, User.find_by_token_for(:email_confirmation, token)
    end
  end
end
