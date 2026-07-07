module EditorSeriesBuilder
  def build_show_series_groups(character, mastery)
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
            {
              skill_group: sg,
              current_level: cs&.current_skill_level.to_i,
              target_level: cs&.target_skill_level.to_i,
              cap: sg.effective_cap(character.server_level_cap)
            }
          end
        # Spec 04 R5: hide groups unreachable under the server cap, unless
        # the character already holds an allocation in them.
        skills.select! do |e|
          e[:cap].positive? || e[:current_level].positive? ||
            e[:target_level].positive?
        end
        { series: series, skills: skills }
      end
      .reject { |group| group[:skills].empty? }
  end

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
        # Spec 04 R5: hide groups unreachable under the server cap, unless
        # allocated on the side being edited.
        skills.select! { |e| e[:cap].positive? || e[:level].positive? }
        { series: series, skills: skills }
      end
      .reject { |group| group[:skills].empty? }
  end
end
