class HomeController < ApplicationController
  allow_unauthenticated_access only: [:index]

  def index
    return unless current_character

    build_skill_window
  end

  def skill_window
    redirect_to root_path and return unless current_character

    build_skill_window
  end

  private

  def build_skill_window
    @window =
      Characters::SkillWindow.new(
        current_character,
        group: params[:group],
        mastery_id: params[:mastery_id]
      )
    @summary = @window.summary
  end
end
