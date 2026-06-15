class SkillPlansController < ApplicationController
  before_action :require_character

  def edit
    build_window(params[:group], params[:mastery_id])
  end

  def update_skill
    result = apply_skill_level
    respond_with_stream(result) do
      build_window(nil, skill_group&.mastery_id)
      render :update_skill
    end
  end

  def update_mastery
    result = apply_mastery_level
    respond_with_stream(result) do
      build_window(nil, params[:mastery_id])
      render :update_mastery
    end
  end

  def max_skills
    build_window(nil, params[:mastery_id])
    groups = @window.series.flat_map { |_, groups| groups }
    result =
      CharacterSkills::MaxAllService.call(current_character, groups, kind: kind)
    if result.success?
      flash.now[:warnings] = result.warnings if result.warnings.any?
      build_window(nil, params[:mastery_id])
      render :refresh_editor
    else
      flash.now[:alert] = result.errors.to_sentence
      build_window(nil, params[:mastery_id])
      render :refresh_editor, status: :unprocessable_entity
    end
  end

  def clear_mastery
    result =
      CharacterMasteries::ClearService.call(
        current_character,
        mastery_id: params[:mastery_id],
        field: kind == :current ? :current : :target
      )
    respond_with_stream(result) do
      build_window(nil, params[:mastery_id])
      render :refresh_editor
    end
  end

  private

  def require_character
    redirect_to root_path unless current_character
  end

  # "current" edits what the player has; anything else edits the plan.
  def kind
    params[:kind] == "current" ? :current : :future
  end
  helper_method :kind

  def skill_group
    @skill_group ||= SkillGroup.find_by(id: params[:skill_group_id])
  end

  def apply_skill_level
    set_skill_level(params[:skill_group_id], params[:level].to_i)
  end

  def set_skill_level(skill_group_id, level)
    exists =
      current_character.character_skills.exists?(skill_group_id: skill_group_id)

    if exists
      level_attr = kind == :current ? :current_skill_level : :target_skill_level
      CharacterSkills::UpdateService.call(
        current_character,
        :skill_group_id => skill_group_id.to_i,
        level_attr => level
      )
    else
      CharacterSkills::AddService.call(
        current_character,
        skill_group_id: skill_group_id.to_i,
        current_skill_level: kind == :current ? level : 0,
        target_skill_level: level
      )
    end
  end

  def apply_mastery_level
    level = params[:level].to_i
    level_attr =
      kind == :current ? :current_mastery_level : :target_mastery_level

    exists =
      current_character.character_masteries.exists?(
        mastery_id: params[:mastery_id]
      )

    if exists
      CharacterMasteries::UpdateService.call(
        current_character,
        :mastery_id => params[:mastery_id].to_i,
        level_attr => level
      )
    else
      CharacterMasteries::AddService.call(
        current_character,
        :mastery_id => params[:mastery_id].to_i,
        level_attr => level
      )
    end
  end

  def respond_with_stream(result)
    if result.success?
      flash.now[:warnings] = result.warnings if result.warnings.any?
      yield
    else
      flash.now[:alert] = result.errors.to_sentence
      render :errors, status: :unprocessable_entity
    end
  end

  def build_window(group, mastery_id)
    @window =
      Characters::SkillWindow.new(
        current_character,
        group: group,
        mastery_id: mastery_id
      )
  end
end
