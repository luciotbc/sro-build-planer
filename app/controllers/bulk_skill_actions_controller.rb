class BulkSkillActionsController < ApplicationController
  include EditorSeriesBuilder

  before_action :set_character
  before_action :set_mastery_and_side

  def max_skills
    result =
      CharacterSkills::MaxMasteryService.call(
        @character,
        mastery: @mastery,
        side: @side
      )
    turbo_respond(result)
  end

  def clear_mastery
    result =
      CharacterMasteries::ClearService.call(
        @character,
        mastery_id: @mastery.id,
        field: @side
      )
    turbo_respond(result)
  end

  def max_mastery
    character_mastery =
      @character.character_masteries.find_by(mastery: @mastery)
    return head :not_found unless character_mastery

    result =
      CharacterMasteries::MaxMasteryLevelService.call(
        character_mastery,
        side: @side,
        cap: @character.server_level_cap
      )
    turbo_respond(result)
  end

  private

  def turbo_respond(result)
    respond_to do |format|
      format.turbo_stream do
        if result.success?
          @mastery_level =
            @character
              .character_masteries
              .find_by(mastery: @mastery)
              &.public_send(:"#{@side}_mastery_level")
              .to_i
          @warnings = result.warnings
          @series_groups =
            build_editor_series_groups(@character, @mastery, @side)
          render "bulk_skill_actions/update"
        else
          render turbo_stream:
                   turbo_stream.replace(
                     "skill-editor-error",
                     partial: "shared/error_toast",
                     locals: {
                       message: result.errors.join(". ")
                     }
                   ),
                 status: :unprocessable_entity
        end
      end
    end
  end

  def set_character
    @character = Current.user.characters.find_by(id: params[:id]) or
      head :not_found
  end

  def set_mastery_and_side
    @side = params[:side]&.to_sym
    return head :unprocessable_entity unless %i[current target].include?(@side)
    @mastery = Mastery.find_by(id: params[:mastery_id])
    head :not_found unless @mastery
  end
end
