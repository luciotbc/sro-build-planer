class CharactersController < ApplicationController
  include EditorSeriesBuilder
  include BuildViewData

  before_action :set_character, only: %i[show edit update destroy]

  def index
    redirect_to root_path
  end

  def show
    load_build_view_data(@character)
  end

  def new
    redirect_to root_path
  end

  def edit
    @side = params[:side].presence&.to_sym
    unless %i[current target].include?(@side)
      if @side.nil?
        @side = :current
      else
        return redirect_to @character
      end
    end

    mastery_id = params[:mastery_id]
    # Every mastery of the race, not only owned ones (spec 07); ordered by id
    # to mirror the in-game order.
    all_masteries = @character.race.masteries.order(:id).to_a
    @grouped_masteries = all_masteries.group_by(&:mastery_type)
    @mastery_types = @grouped_masteries.keys.sort
    @active_mastery =
      (all_masteries.find { |m| m.id.to_s == mastery_id.to_s } if mastery_id) ||
        @grouped_masteries[@mastery_types.first]&.first

    if @active_mastery
      mastery_level_attr = :"#{@side}_mastery_level"
      @mastery_level =
        @character
          .character_masteries
          .find_by(mastery: @active_mastery)
          &.public_send(mastery_level_attr)
          .to_i
      @series_groups =
        build_editor_series_groups(@character, @active_mastery, @side)
    else
      @series_groups = []
    end
  end

  def create
    result =
      Characters::CreateService.call(character_params.merge(user: Current.user))
    if result.success?
      redirect_to result.data, notice: t(".created")
    else
      redirect_to root_path, alert: result.errors.join(", ")
    end
  end

  def update
    result = Characters::UpdateService.call(@character, character_params)
    if result.success?
      redirect_to @character, notice: t(".updated")
    else
      # :edit is the skill-editor screen, not a character form — failures from
      # the edit-character modal go back to the planner (spec 05 R4: no clamp).
      redirect_to @character,
                  alert: result.errors.join(", "),
                  status: :see_other
    end
  end

  def destroy
    Characters::DeleteService.call(@character)
    redirect_to characters_path, notice: t(".deleted"), status: :see_other
  end

  private

  def set_character
    @character = Current.user.characters.find_by(id: params[:id]) or
      head :not_found
  end

  def character_params
    params.require(:character).permit(:name, :race_id, :server_level_cap)
  end
end
