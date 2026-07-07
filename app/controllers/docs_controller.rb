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
        <%= render "shared/char_bar", name: "BuckTBC", race: "Chinese", level: 110 %>
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
      turbo_stream: <<~ERB
        # After the server clamps a skill level, re-render just the stat rows:
        # app/views/characters/update.turbo_stream.erb
        <%= turbo_stream.replace "skill-points", partial: "shared/stat_row",
              locals: { label: "Skill points", current: @current, delta: @delta, planned: @planned } %>
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
