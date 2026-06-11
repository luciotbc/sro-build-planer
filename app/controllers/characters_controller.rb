class CharactersController < ApplicationController
  def index
    @characters = Current.user.characters.includes(:race).order(:id)
  end

  def new
    @character = Current.user.characters.build
    @races = Race.order(:external_id)
  end

  def create
    result = Characters::CreateService.call(character_params)

    if result.success?
      select_character(result.data)
      redirect_to root_path, notice: "Character created"
    else
      @character = Current.user.characters.build(character_params.except(:user))
      @races = Race.order(:external_id)
      flash.now[:alert] = result.errors.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def select
    character = Current.user.characters.find(params[:id])
    select_character(character)
    redirect_to root_path
  end

  private

  def character_params
    params
      .require(:character)
      .permit(:name, :race_id, :target_level)
      .merge(user: Current.user)
  end
end
