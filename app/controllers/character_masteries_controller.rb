class CharacterMasteriesController < ApplicationController
  include EditorSeriesBuilder

  before_action :set_character

  # PATCH /characters/:character_id/character_masteries/:mastery_id
  # Updates the mastery level for one side (spec 06 R4, spec 03 R7).
  # On decrease: auto-downgrades skills above the new mastery level.
  # Responds with Turbo Stream: replaces mastery header + all skill rows.
  def update
    side = params[:side]&.to_sym
    return head :unprocessable_entity unless %i[current target].include?(side)

    new_level = params[:level].to_i
    mastery_id = params[:mastery_id].to_i
    level_key = :"#{side}_mastery_level"

    result =
      CharacterMasteries::UpdateService.call(
        @character,
        :mastery_id => mastery_id,
        level_key => new_level
      )

    respond_to do |format|
      format.turbo_stream do
        if result.success?
          cm = result.data
          @active_mastery = cm.mastery
          @mastery_level = cm.public_send(level_key).to_i
          @side = side
          @series_groups =
            build_editor_series_groups(@character, @active_mastery, side)
          render "character_masteries/update"
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

  private

  def set_character
    @character = Current.user.characters.find_by(id: params[:character_id]) or
      head :not_found
  end
end
