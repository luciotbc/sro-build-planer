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
          user: @params[:user],
          server_level_cap: @params.fetch(:server_level_cap, 110)
        )

      if character.save
        ServiceResult.ok(data: character)
      else
        ServiceResult.fail(errors: character.errors.full_messages)
      end
    end
  end
end
