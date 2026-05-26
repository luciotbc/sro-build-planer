module Characters
  class UpdateService
    def self.call(character, params) = new(character, params).call

    def initialize(character, params)
      @character = character
      @params = params
    end

    def call
      errors = []

      validate_name(errors)
      race_changing = validate_race(errors)
      validate_levels(errors)
      check_mastery_compatibility(errors) unless race_changing || errors.any?

      return ServiceResult.fail(errors:) if errors.any?

      persist!(race_changing)
      ServiceResult.ok(data: @character)
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end

    private

    def validate_name(errors)
      return unless @params.key?(:name)

      errors << "Name can't be blank" if @params[:name].blank?
    end

    def validate_race(errors)
      return false unless @params.key?(:race_id)
      return false if @params[:race_id] == @character.race_id

      errors << "Race must exist" unless Race.exists?(@params[:race_id])
      true
    end

    def validate_levels(errors)
      %i[current_level target_level].each do |attr|
        next unless @params.key?(attr)

        value = @params[attr]
        next if value.nil?

        unless value.is_a?(Integer)
          errors << "#{attr.to_s.humanize} must be an integer"
          next
        end

        if value < 0 || value > Character::MAX_LEVEL
          errors << "#{attr.to_s.humanize} must be between 0 and #{Character::MAX_LEVEL}"
        end
      end
    end

    def check_mastery_compatibility(errors)
      return unless @params.key?(:current_level) || @params.key?(:target_level)

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

      return if incompatible.empty?

      names = incompatible.map { |cm| cm.mastery.name }.join(", ")
      errors << "Cannot reduce level: incompatible masteries: #{names}"
    end

    def exceeds?(mastery_level, char_level)
      mastery_level && char_level && mastery_level > char_level
    end

    def persist!(race_changing)
      ActiveRecord::Base.transaction do
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
