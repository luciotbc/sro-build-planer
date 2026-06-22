module CharacterMasteries
  class MaxMasteryLevelService
    def self.call(character_mastery, side:, cap:) =
      new(character_mastery, side, cap).call

    def initialize(character_mastery, side, cap)
      @character_mastery = character_mastery
      @side = side
      @cap = cap
    end

    def call
      unless %i[current target].include?(@side)
        return ServiceResult.fail(errors: ["Invalid side"])
      end

      field = :"#{@side}_mastery_level"
      @character_mastery.update!(field => @cap)

      ServiceResult.ok(data: @character_mastery)
    rescue => e
      ServiceResult.fail(errors: [e.message])
    end
  end
end
