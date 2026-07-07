# Loads the read-only build view data shared by the owner planner
# (characters#show) and the public shared page (shared_builds#show).
module BuildViewData
  extend ActiveSupport::Concern
  include EditorSeriesBuilder

  private

  def load_build_view_data(character)
    # The navigation lists every mastery of the character's race (spec 07),
    # ordered by id to mirror the in-game order, not only the owned ones.
    all_masteries = character.race.masteries.order(:id).to_a

    @grouped_masteries = all_masteries.group_by(&:mastery_type)
    @mastery_types = @grouped_masteries.keys.sort

    @active_mastery =
      if params[:mastery_id]
        all_masteries.find { |m| m.id.to_s == params[:mastery_id].to_s }
      end
    @active_mastery ||= @grouped_masteries[@mastery_types.first]&.first

    if @active_mastery
      cm = character.character_masteries.find_by(mastery: @active_mastery)
      @current_mastery_level = cm&.current_mastery_level.to_i
      @target_mastery_level = cm&.target_mastery_level.to_i
      @series_groups = build_show_series_groups(character, @active_mastery)
    else
      @current_mastery_level = 0
      @target_mastery_level = 0
      @series_groups = []
    end

    @summary = Builds::SummaryService.call(character).data
  end
end
