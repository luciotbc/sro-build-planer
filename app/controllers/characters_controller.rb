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
    @side = params[:side].presence&.to_sym
    unless %i[current target].include?(@side)
      if @side.nil?
        @side = :current
      else
        return redirect_to @character
      end
    end

    mastery_id = params[:mastery_id]
    all_masteries =
      @character.character_masteries.includes(:mastery).map(&:mastery)
    @active_mastery =
      (all_masteries.find { |m| m.id.to_s == mastery_id.to_s } if mastery_id) ||
        all_masteries.first

    if @active_mastery
      skill_level_attr = :"#{@side}_skill_level"
      mastery_level_attr = :"#{@side}_mastery_level"
      @mastery_level =
        @character
          .character_masteries
          .find_by(mastery: @active_mastery)
          &.public_send(mastery_level_attr)
          .to_i
      @series_groups =
        @active_mastery
          .skill_series
          .order(:row_position)
          .map do |series|
            skill_groups =
              series
                .skill_groups
                .includes(:skills, :character_skills)
                .order(:col_position)
            character_skills_by_group =
              @character
                .character_skills
                .where(skill_group: skill_groups)
                .index_by(&:skill_group_id)
            skills_with_data =
              skill_groups.map do |sg|
                cs = character_skills_by_group[sg.id]
                level = cs&.public_send(skill_level_attr).to_i
                cap = sg.effective_cap(@character.server_level_cap)
                { skill_group: sg, level: level, cap: cap }
              end
            { series: series, skills: skills_with_data }
          end
    else
      @series_groups = []
    end
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
