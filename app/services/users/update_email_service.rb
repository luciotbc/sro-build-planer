module Users
  class UpdateEmailService
    def self.call(user:, email_address:) = new(user, email_address).call

    def initialize(user, email_address)
      @user = user
      @email_address = email_address
    end

    def call
      @user.email_address = @email_address

      unless @user.email_address_changed?
        return(
          ServiceResult.ok(
            data: @user,
            warnings: [I18n.t("settings.email.unchanged")]
          )
        )
      end

      # Changing the login email invalidates the previous verification: the
      # user must prove ownership of the new address (spec 09).
      @user.email_confirmed_at = nil

      if @user.save
        UsersMailer.email_confirmation(@user).deliver_later
        ServiceResult.ok(data: @user)
      else
        ServiceResult.fail(errors: @user.errors.full_messages)
      end
    end
  end
end
