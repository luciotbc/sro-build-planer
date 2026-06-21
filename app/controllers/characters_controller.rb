class CharactersController < ApplicationController
  before_action :set_character, only: %i[show edit update destroy]

  def index
    @characters = Current.user.characters.order(:name)
  end

  def show
    character_masteries =
      @character.character_masteries.includes(:mastery).order("masteries.name")
    all_masteries = character_masteries.map(&:mastery)

    @grouped_masteries = all_masteries.group_by(&:mastery_type)
    @mastery_types = @grouped_masteries.keys.sort

    @active_mastery =
      if params[:mastery_id]
        all_masteries.find { |m| m.id.to_s == params[:mastery_id].to_s }
      end
    @active_mastery ||= @grouped_masteries[@mastery_types.first]&.first

    @character_skills =
      if @active_mastery
        @character
          .character_skills
          .joins(:skill_group)
          .where(skill_groups: { mastery_id: @active_mastery.id })
          .includes(skill_group: [])
          .order("skill_groups.name")
      else
        []
      end
    @summary = Builds::SummaryService.call(@character).data
  end

  def new
    @character = Character.new
  end

  def edit
  end

  def create
    result =
      Characters::CreateService.call(character_params.merge(user: Current.user))
    if result.success?
      redirect_to result.data, notice: "Character created."
    else
      @character = Character.new(character_params)
      @character.errors.add(:base, result.errors.join(", "))
      render :new, status: :unprocessable_entity
    end
  end

  def update
    result = Characters::UpdateService.call(@character, character_params)
    if result.success?
      redirect_to @character, notice: "Character updated."
    else
      @character.errors.add(:base, result.errors.join(", "))
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Characters::DeleteService.call(@character)
    redirect_to characters_path,
                notice: "Character deleted.",
                status: :see_other
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
