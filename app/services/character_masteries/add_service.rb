module CharacterMasteries
  class AddService
    def self.call(character, params) = new(character, params).call

    def initialize(character, params)
      @character = character
      @params = params
      @warnings = []
    end

    def call
      mastery = Mastery.find_by(id: @params[:mastery_id])
      return ServiceResult.fail(errors: ["Mastery must exist"]) unless mastery

      unless mastery.race_id == @character.race_id
        return(
          ServiceResult.fail(
            errors: ["Mastery race does not match character race"]
          )
        )
      end

      if CharacterMastery.exists?(character: @character, mastery:)
        return(
          ServiceResult.fail(
            errors: ["Mastery has already been added to this character"]
          )
        )
      end

      current_mastery_level = @params.fetch(:current_mastery_level, 0)
      target_mastery_level = @params.fetch(:target_mastery_level, 0)

      ActiveRecord::Base.transaction do
        sync_character_levels(current_mastery_level, target_mastery_level)

        cm =
          CharacterMastery.create!(
            character: @character,
            mastery:,
            current_mastery_level:,
            target_mastery_level:
          )

        ServiceResult.ok(data: cm, warnings: @warnings)
      end
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end

    private

    def sync_character_levels(current_mastery_level, target_mastery_level)
      updates = {}

      if current_mastery_level > (@character.current_level || 0)
        updates[:current_level] = current_mastery_level
        @warnings << "character.current_level updated to #{current_mastery_level}"
      end

      if target_mastery_level > (@character.target_level || 0)
        updates[:target_level] = target_mastery_level
        @warnings << "character.target_level updated to #{target_mastery_level}"
      end

      @character.update!(updates) if updates.any?
    end
  end
end
