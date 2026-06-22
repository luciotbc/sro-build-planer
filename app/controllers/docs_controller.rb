class DocsController < ApplicationController
  allow_unauthenticated_access only: :design_system

  before_action :ensure_development

  # Living design system reference - renders inside the app shell using only the
  # app's own tokens, component classes and shared partials so docs cannot drift
  # from the real product. Usage snippets live here as plain heredocs because a
  # `%>` inside an ERB template would close the tag prematurely.
  def design_system
    @snippets = {
      button: <<~ERB,
        <%= render "shared/button", label: "Edit Planned" %>
        <%= render "shared/button", label: "Edit Current", variant: :ghost %>
        <%= render "shared/button", label: "\u00d7", variant: :icon, attrs: { "aria-label": "Close" } %>
        <%= render "shared/chars_pill", count: 3 %>
      ERB
      mastery_nav: <<~ERB,
        <%# Mastery navigation component (characters/show) %>
        <%# Row 1: mastery type pills; Row 2: mastery sub-tabs per group %>
        <%# Stimulus controller: mastery-tabs. State: in-memory per group. %>
        <%# See docs/specs/07-mastery-navigation.md for full behavior spec. %>
      ERB
      badge: <<~ERB,
        <%= render "shared/badge", text: "Current" %>
        <%= render "shared/badge", text: "Planned", variant: :planned %>
        <%= render "shared/badge", text: "MAX", variant: :max %>
        <%= render "shared/legend_badge" %>
      ERB
      stat_row: <<~ERB,
        <div class="stat-merged">
          <%= render "shared/stat_row", label: "Skill points", current: "3,210,000", delta: "3,230,000", planned: "6,440,000" %>
          <%= render "shared/stat_row", label: "Required level", current: 92, delta: 18, planned: 110 %>
        </div>
      ERB
      char_bar: <<~ERB,
        <%= render "shared/char_bar", name: "BuckTBC", race: "Chinese", level: 110, initial: "\u534e" %>
      ERB
      skill_row: <<~ERB,
        <div class="skill-card">
          <%= render "shared/skill_row", name: "Cyclone I", icon: "skill-a.png", level: 16, max: 30 %>
          <%= render "shared/skill_row", name: "Cyclone II", icon: "skill-c.png", level: 42, max: 42 %>
        </div>
      ERB
      topbar: <<~ERB,
        <%= render "shared/topbar" %>
        <%= render "shared/topbar", actions: capture { %>
          <%= render "shared/button", label: "New character" %>
        <% } %>
      ERB
      overlays: <<~ERB,
        <%= render "shared/modal", title: "Edit \u2014 Planned", trigger_label: "Open modal" %>
        <%= render "shared/drawer", title: "Characters", trigger_label: "Open drawer" %>
        <%= render "shared/sheet", title: "Filters", trigger_label: "Open sheet" %>
      ERB
      turbo_frame: <<~ERB,
        <%# Lazy-load a modal's body inside a Turbo Frame %>
        <%= turbo_frame_tag "modal", src: edit_character_path(@character), loading: :lazy %>
      ERB
      turbo_stream: <<~ERB,
        # After the server clamps a skill level, re-render just the stat rows:
        # app/views/characters/update.turbo_stream.erb
        <%= turbo_stream.replace "skill-points", partial: "shared/stat_row",
              locals: { label: "Skill points", current: @current, delta: @delta, planned: @planned } %>
      ERB
      toast: <<~ERB,
        <%# Info / warning toast (auto-dismissed after 4 s via toast controller) %>
        <%= render "shared/toast", message: "Prerequisite Guard added automatically." %>
        <%# Error variant %>
        <%= render "shared/toast", message: "Cannot remove: Slash depends on Guard.", variant: "error" %>
      ERB
      error_toast: <<~ERB,
        <%# Inline error banner inside the skill editor %>
        <%= render "shared/error_toast", message: "Cannot remove: a higher skill depends on this one." %>
      ERB
      empty_state: <<~ERB,
        <%# No characters yet — with CTA link %>
        <%= render "shared/empty_state",
              title: "No characters yet",
              description: "Create your first character to start planning your build.",
              link_url: new_character_path,
              link_label: "Create character" %>
        <%# No skills in mastery — no link %>
        <%= render "shared/empty_state",
              title: "No skills in this mastery",
              description: "Select a mastery with skills to start planning." %>
      ERB
      stats_summary: <<~ERB,
        <%# Full summary panel from Builds::SummaryService %>
        <%= render "shared/stats_summary", summary: {
              skill_points: { current: "3,210,000", delta: "1,230,000", planned: "4,440,000" },
              mastery_total: { current: 210, delta: 90, planned: 300 },
              required_level: { current: 92, delta: 18, planned: 110 }
            } %>
      ERB
      mastery_header: <<~ERB,
        <%# Mastery level control: stepper + slider + Max button (spec 06 R4) %>
        <%# Rendered in characters#edit for each active mastery, per side. %>
        <%# Stimulus: stepper controller (same as skill rows). %>
        <%# See app/views/shared/_mastery_header.html.erb for locals. %>
        <%= render "shared/mastery_header",
              character: @character,
              mastery: @mastery,
              mastery_level: 75,
              side: :current %>
      ERB
      editor_skill_row: <<~ERB,
        <%# Skill editor row: name, level, ±stepper, info panel trigger (spec 06). %>
        <%# level=0 → unlearned; cap = effective_cap (spec 04 R4). %>
        <%# Stimulus: stepper + dialog controllers. %>
        <%# See app/views/shared/_editor_skill_row.html.erb for locals. %>
        <%= render "shared/editor_skill_row",
              character: @character,
              skill_group: @skill_group,
              level: 7,
              cap: 10,
              side: :current %>
      ERB
      chars_drawer: <<~ERB
        <%# Right-side drawer listing user characters; trigger is chars-pill. %>
        <%= render "shared/chars_drawer",
              characters: Current.user.characters.order(:name) %>
      ERB
    }
  end

  private

  # Belt-and-braces guard: the route is only drawn in development, but refuse the
  # action anywhere else in case it is ever wired up by mistake.
  def ensure_development
    head :not_found unless Rails.env.development?
  end
end
