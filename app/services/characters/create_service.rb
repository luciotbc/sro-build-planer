module Characters
  class CreateService
    def self.call(params) = new(params).call

    def initialize(params)
      @params = params
    end

    def call
      target_level = @params.fetch(:target_level, nil)
      if target_level && !Character::LEVEL_CAPS.key?(target_level.to_i)
        return(
          ServiceResult.fail(
            errors: [
              I18n.t(
                "errors.character.invalid_target_level",
                valid: Character::LEVEL_CAPS.keys.join(", ")
              )
            ]
          )
        )
      end

      character =
        Character.new(
          name: @params[:name],
          race_id: @params[:race_id],
          user: @params[:user],
          current_level: @params.fetch(:current_level, 0),
          target_level: target_level || 0
        )

      if character.save
        ServiceResult.ok(data: character)
      else
        ServiceResult.fail(errors: character.errors.full_messages)
      end
    end
  end
end
