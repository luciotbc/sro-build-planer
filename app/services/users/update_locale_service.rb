module Users
  class UpdateLocaleService
    def self.call(user:, locale:) = new(user, locale).call

    def initialize(user, locale)
      @user = user
      @locale = locale.to_s
    end

    # Validates the requested locale and, for a signed-in user, persists it to
    # users.locale. Guests have no record to write to, so the locale is only
    # validated — the controller keeps a guest's choice in the session (spec 08
    # R12). `data` is the resolved locale string in both cases.
    def call
      return unsupported unless supported?

      if @user
        @user.locale = @locale
        unless @user.save
          return ServiceResult.fail(errors: @user.errors.full_messages)
        end
      end

      ServiceResult.ok(data: @locale)
    end

    private

    def supported?
      I18n.available_locales.map(&:to_s).include?(@locale)
    end

    def unsupported
      ServiceResult.fail(errors: [I18n.t("errors.locale.unsupported")])
    end
  end
end
