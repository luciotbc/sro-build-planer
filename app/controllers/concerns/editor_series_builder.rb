module EditorSeriesBuilder
  def build_editor_series_groups(character, mastery, side)
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
          character
            .character_skills
            .where(skill_group: skill_groups)
            .index_by(&:skill_group_id)
        skills =
          skill_groups.map do |sg|
            cs = cs_by_group[sg.id]
            level = cs&.public_send(skill_level_attr).to_i
            cap = sg.effective_cap(character.server_level_cap)
            { skill_group: sg, level: level, cap: cap }
          end
        { series: series, skills: skills }
      end
  end
end
