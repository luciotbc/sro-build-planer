module Users
  class UpdateLocaleService
    def self.call(user:, locale:) = new(user, locale).call

    def initialize(user, locale)
      @user = user
      @locale = locale.to_s
    end

    def call
      @user.locale = @locale

      if @user.save
        ServiceResult.ok(data: @user)
      else
        ServiceResult.fail(errors: @user.errors.full_messages)
      end
    end
  end
end
