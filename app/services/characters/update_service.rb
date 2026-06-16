module Characters
  class UpdateService
    def self.call(character, params) = new(character, params).call

    def initialize(character, params)
      @character = character
      @params = params
    end

    def call
      race_changing =
        @params.key?(:race_id) && @params[:race_id] != @character.race_id

      @character.assign_attributes(
        @params.slice(:name, :race_id, :current_level, :target_level)
      )
      unless @character.valid?
        return ServiceResult.fail(errors: @character.errors.full_messages)
      end

      mastery_errors = mastery_compatibility_errors unless race_changing
      return ServiceResult.fail(errors: mastery_errors) if mastery_errors&.any?

      persist!(race_changing)
      ServiceResult.ok(data: @character)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.fail(errors: e.record.errors.full_messages)
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end

    private

    def mastery_compatibility_errors
      unless @params.key?(:current_level) || @params.key?(:target_level)
        return []
      end

      new_current = @params.fetch(:current_level, @character.current_level)
      new_target = @params.fetch(:target_level, @character.target_level)

      incompatible =
        @character
          .character_masteries
          .includes(:mastery)
          .select do |cm|
            exceeds?(cm.current_mastery_level, new_current) ||
              exceeds?(cm.target_mastery_level, new_target)
          end

      return [] if incompatible.empty?

      names = incompatible.map { |cm| cm.mastery.name }.join(", ")
      ["Cannot reduce level: incompatible masteries: #{names}"]
    end

    def exceeds?(mastery_level, char_level)
      mastery_level && char_level && mastery_level > char_level
    end

    def persist!(race_changing)
      ApplicationRecord.transaction do
        if race_changing
          @character.character_skills.destroy_all
          @character.character_masteries.destroy_all
        end

        @character.update!(
          @params.slice(:name, :race_id, :current_level, :target_level)
        )
      end
    end
  end
end
