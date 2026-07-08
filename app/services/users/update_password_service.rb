module Users
  class UpdatePasswordService
    def self.call(
      user:,
      current_password:,
      password:,
      password_confirmation:,
      current_session: nil
    )
      new(
        user,
        current_password,
        password,
        password_confirmation,
        current_session
      ).call
    end

    def initialize(
      user,
      current_password,
      password,
      password_confirmation,
      current_session
    )
      @user = user
      @current_password = current_password
      @password = password
      @password_confirmation = password_confirmation
      @current_session = current_session
    end

    def call
      unless @user.authenticate(@current_password.to_s)
        return(
          ServiceResult.fail(
            errors: [I18n.t("settings.password.wrong_current")]
          )
        )
      end

      @user.password = @password
      @user.password_confirmation = @password_confirmation

      if @user.save
        revoke_other_sessions
        ServiceResult.ok(data: @user)
      else
        ServiceResult.fail(errors: @user.errors.full_messages)
      end
    end

    private

    # Changing the password revokes every other device's session; the session
    # performing the change stays valid (spec 09).
    def revoke_other_sessions
      sessions = @user.sessions
      sessions = sessions.where.not(id: @current_session.id) if @current_session
      sessions.destroy_all
    end
  end
end
