module ApplicationHelper
  # Inline SVG crest for a race (design: ChineseGlyph / EuropeanGlyph).
  def race_glyph(race, size: 22, active: true)
    fg = active ? "#f4d878" : "#7a6a40"

    case race&.name
    when "European"
      bg = active ? "#1f3a6b" : "#15243a"
      tag.svg viewBox: "0 0 32 32", width: size, height: size, class: "block" do
        safe_join(
          [
            tag.path(
              d: "M6 7 L26 7 L26 18 Q26 24 16 28 Q6 24 6 18 Z",
              fill: bg,
              stroke: fg,
              "stroke-width": "1.5"
            ),
            tag.path(
              d: "M16 9 L16 25 M9 14 L23 14",
              stroke: fg,
              "stroke-width": "2",
              "stroke-linecap": "round"
            )
          ]
        )
      end
    else
      bg = active ? "#8b1f1f" : "#2a1818"
      tag.svg viewBox: "0 0 32 32", width: size, height: size, class: "block" do
        safe_join(
          [
            tag.circle(
              cx: 16,
              cy: 16,
              r: 13,
              fill: bg,
              stroke: fg,
              "stroke-width": "1.5"
            ),
            tag.path(
              d: "M16 7 Q10 12 12 18 Q14 22 16 24 Q18 22 20 18 Q22 12 16 7 Z",
              fill: fg,
              opacity: "0.85"
            ),
            tag.circle(cx: 16, cy: 14, r: "1.6", fill: bg)
          ]
        )
      end
    end
  end

  # The "Characters (n)" pill that opens the drawer from the topbar.
  def characters_pill(count)
    link_to characters_path,
            class:
              "flex items-center gap-2 rounded-[999px] bg-card border border-line " \
                "pl-2.5 pr-1.5 py-1.5 cursor-pointer hover:bg-card-hi",
            data: {
              turbo_frame: "modal"
            } do
      safe_join(
        [
          tag.span("Characters", class: "text-xs text-text-dim"),
          tag.span(
            count,
            class:
              "flex h-5 w-5 items-center justify-center rounded-full " \
                "bg-brass text-bg text-[11px] font-extrabold tnum"
          )
        ]
      )
    end
  end
end
