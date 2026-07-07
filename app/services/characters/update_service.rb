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
        @params.slice(:name, :race_id, :server_level_cap)
      )
      unless @character.valid?
        return ServiceResult.fail(errors: @character.errors.full_messages)
      end

      cap_errors = server_cap_compatibility_errors unless race_changing
      return ServiceResult.fail(errors: cap_errors) if cap_errors&.any?

      persist!(race_changing)
      ServiceResult.ok(data: @character)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.fail(errors: e.record.errors.full_messages)
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end

    private

    def server_cap_compatibility_errors
      return [] unless @params.key?(:server_level_cap)

      new_cap = @params[:server_level_cap].to_i

      incompatible =
        @character
          .character_masteries
          .includes(:mastery)
          .select do |cm|
            (cm.current_mastery_level && cm.current_mastery_level > new_cap) ||
              (cm.target_mastery_level && cm.target_mastery_level > new_cap)
          end

      return [] if incompatible.empty?

      names = incompatible.map { |cm| cm.mastery.name }.join(", ")
      [I18n.t("errors.server_level_cap.masteries_exceed", mastery_names: names)]
    end

    def persist!(race_changing)
      ApplicationRecord.transaction do
        if race_changing
          @character.character_skills.destroy_all
          @character.character_masteries.destroy_all
        end

        @character.update!(@params.slice(:name, :race_id, :server_level_cap))
      end
    end
  end
end
