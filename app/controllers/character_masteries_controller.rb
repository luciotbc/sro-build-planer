class CharacterMasteriesController < ApplicationController
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
          @series_groups = build_series_groups(@active_mastery, side)
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

  def build_series_groups(mastery, side)
    skill_level_attr = :"#{side}_skill_level"
    mastery
      .skill_series
      .order(:row_position)
      .map do |series|
        skill_groups =
          series
            .skill_groups
            .includes(:skills, :character_skills)
            .order(:col_position)
        cs_by_group =
          @character
            .character_skills
            .where(skill_group: skill_groups)
            .index_by(&:skill_group_id)
        skills =
          skill_groups.map do |sg|
            cs = cs_by_group[sg.id]
            level = cs&.public_send(skill_level_attr).to_i
            cap = sg.effective_cap(@character.server_level_cap)
            { skill_group: sg, level: level, cap: cap }
          end
        { series: series, skills: skills }
      end
  end

  def set_character
    @character = Current.user.characters.find_by(id: params[:character_id]) or
      head :not_found
  end
end
