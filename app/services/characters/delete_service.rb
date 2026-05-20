module Characters
  class DeleteService
    def self.call(character) = new(character).call

    def initialize(character)
      @character = character
    end

    def call
      ActiveRecord::Base.transaction do
        @character.character_skills.delete_all
        @character.character_masteries.delete_all
        @character.destroy!
      end

      ServiceResult.ok
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end
  end
end
