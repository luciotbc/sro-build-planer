class UsersMailerPreview < ActionMailer::Preview
  def email_confirmation
    UsersMailer.email_confirmation(User.take)
  end
end
