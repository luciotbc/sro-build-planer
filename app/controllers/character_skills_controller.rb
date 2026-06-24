class CharacterSkillsController < ApplicationController
  include EditorSeriesBuilder

  before_action :set_character

  # PATCH /characters/:character_id/character_skills/:skill_group_id
  # Persists a single ± stepper change for one side (spec 06 R2/R3).
  # Responds with Turbo Stream: replaces the skill row + the mastery header
  # on success (the header keeps the slider and the Skills counter in sync,
  # including the auto-bumped mastery level), or the error placeholder on failure.
  #
  # Effective cap is enforced at the view layer (stepper max, spec 04 R4);
  # max_skill_level is enforced by UpdateService.
  def update
    side = params[:side]&.to_sym
    return head :unprocessable_entity unless %i[current target].include?(side)

    new_level = params[:level].to_i
    sg_id = params[:skill_group_id].to_i

    cs = @character.character_skills.find_by(skill_group_id: sg_id)
    result = resolve_update(cs, sg_id, side, new_level)

    respond_to do |format|
      format.turbo_stream do
        if result.success?
          sg = SkillGroup.find(sg_id)
          cs = @character.character_skills.find_by(skill_group_id: sg_id)
          level = cs&.public_send(:"#{side}_skill_level").to_i
          cap = sg.effective_cap(@character.server_level_cap)
          streams = [
            turbo_stream.replace(
              "skill-row-#{sg_id}",
              partial: "shared/editor_skill_row",
              locals: {
                character: @character,
                skill_group: sg,
                level: level,
                cap: cap,
                side: side
              }
            )
          ]
          streams << mastery_header_stream(sg.mastery, side)
          result.warnings.each do |warning|
            streams << turbo_stream.append(
              "toast-container",
              partial: "shared/toast",
              locals: {
                message: warning
              }
            )
          end
          render turbo_stream: streams
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

  # Re-renders the mastery header so the slider, "Mastery Lv" and "Skills"
  # counters stay consistent after a skill edit (a skill can auto-raise the
  # mastery level via PrerequisiteResolver, and the allocated count changes
  # on every step).
  def mastery_header_stream(mastery, side)
    mastery_level =
      @character
        .character_masteries
        .find_by(mastery: mastery)
        &.public_send(:"#{side}_mastery_level")
        .to_i
    series_groups = build_editor_series_groups(@character, mastery, side)
    turbo_stream.replace(
      "mastery-header",
      partial: "shared/mastery_header",
      locals: {
        character: @character,
        mastery: mastery,
        mastery_level: mastery_level,
        side: side,
        skills_allocated:
          series_groups.sum { |g| g[:skills].sum { |e| e[:level] } },
        skills_total: series_groups.sum { |g| g[:skills].sum { |e| e[:cap] } }
      }
    )
  end

  def resolve_update(cs, sg_id, side, new_level)
    level_key = :"#{side}_skill_level"
    if cs
      CharacterSkills::UpdateService.call(
        @character,
        :skill_group_id => sg_id,
        level_key => new_level
      )
    elsif new_level > 0
      other_key =
        (side == :current ? :target_skill_level : :current_skill_level)
      CharacterSkills::AddService.call(
        @character,
        :skill_group_id => sg_id,
        level_key => new_level,
        other_key => 0
      )
    else
      ServiceResult.ok(data: nil, warnings: [])
    end
  end

  def set_character
    @character = Current.user.characters.find_by(id: params[:character_id]) or
      head :not_found
  end
end
