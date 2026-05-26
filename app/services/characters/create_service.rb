module Characters
  class CreateService
    def self.call(params) = new(params).call

    def initialize(params)
      @params = params
    end

    def call
      character =
        Character.new(
          name: @params[:name],
          race_id: @params[:race_id],
          current_level: @params.fetch(:current_level, 0),
          target_level: @params.fetch(:target_level, 0)
        )

      if character.save
        ServiceResult.ok(data: character)
      else
        ServiceResult.fail(errors: character.errors.full_messages)
      end
    end
  end
end
