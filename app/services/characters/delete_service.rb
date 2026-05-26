module Characters
  class DeleteService
    def self.call(character) = new(character).call

    def initialize(character)
      @character = character
    end

    def call
      @character.destroy!
      ServiceResult.ok
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end
  end
end
