module Users
  class DeleteAccountService
    # The literal confirmation word is "DELETE" in every locale (spec 09 R9).
    CONFIRMATION_WORD = "DELETE".freeze

    def self.call(user:, confirmation:) = new(user, confirmation).call

    def initialize(user, confirmation)
      @user = user
      @confirmation = confirmation
    end

    def call
      unless @confirmation == CONFIRMATION_WORD
        return(
          ServiceResult.fail(
            errors: [I18n.t("settings.delete_account.confirmation_mismatch")]
          )
        )
      end

      @user.destroy!
      ServiceResult.ok
    end
  end
end
