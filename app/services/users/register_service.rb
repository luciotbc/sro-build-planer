module Users
  class RegisterService
    def self.call(params) = new(params).call

    def initialize(params)
      @params = params
    end

    def call
      user =
        User.new(
          email_address: @params[:email_address],
          password: @params[:password],
          password_confirmation: @params[:password_confirmation],
          email_opt_in: @params.fetch(:email_opt_in, false)
        )

      if user.save
        UsersMailer.email_confirmation(user).deliver_later
        ServiceResult.ok(data: user)
      else
        ServiceResult.fail(errors: user.errors.full_messages)
      end
    end
  end
end
