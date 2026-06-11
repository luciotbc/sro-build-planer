// Fullscreen planner modal — opens when the user taps "Open planner" on a
// PlannerCard. Touch-friendly editing of one mastery's skills.
//
// Hierarchy:  Group > Mastery > Skill Series > Skill > Level
//
// Skill level cap in this prototype = 42 (per spec).
// Mastery level cap = 110.

const { useState: useStateFS, useEffect: useEffectFS, useRef: useRefFS, useCallback: useCallbackFS } = React;

// Race glyph (matches Home page avatar)
function FsChineseGlyph({ size = 34, active = true }) {
  const fg = active ? "#f4d878" : "#7a6a40";
  const bg = active ? "#8b1f1f" : "#2a1818";
  return (
    <svg viewBox="0 0 32 32" width={size} height={size} style={{ display: "block" }}>
      <circle cx="16" cy="16" r="13" fill={bg} stroke={fg} strokeWidth="1.5" />
      <path d="M16 7 Q10 12 12 18 Q14 22 16 24 Q18 22 20 18 Q22 12 16 7 Z" fill={fg} opacity="0.85" />
      <circle cx="16" cy="14" r="1.6" fill={bg} />
    </svg>);

}

const MASTERY_MAX = 110;
const SKILL_LEVEL_MAX = 42;

// ─── Data ────────────────────────────────────────────────────────────────────

// We pull the 5 skill icons from the assets folder (already extracted earlier).
const FS_SKILL_ICONS = [
"assets/skill-a.png",
"assets/skill-b.png",
"assets/skill-c.png",
"assets/skill-d.png",
"assets/skill-e.png"];


const SERIES_GLYPHS = ["✦", "✸", "✺", "✹", "❖", "✶"];

function buildPlannerState() {
  // 3 groups × 3 masteries × 4 series × 5 skills (sample data).
  const makeMastery = (id, name, level) => ({
    id, name, level,
    series: [
    { id: `${id}-pierce`, name: "Pierce series", glyph: "✦",
      skills: makeSkills("pi", "Pierce", [12, 10, 8, 6, 4]) },
    { id: `${id}-cyclone`, name: "Cyclone series", glyph: "✸",
      skills: makeSkills("cy", "Cyclone", [0, 0, 0, 0, 0]) },
    { id: `${id}-frost`, name: "Frost series", glyph: "✺",
      skills: makeSkills("fr", "Frost", [9, 7, 5, 3, 0]) },
    { id: `${id}-shadow`, name: "Shadow series", glyph: "✹",
      skills: makeSkills("sh", "Shadow", [6, 4, 0, 0, 0]) }]

  });
  const makeSkills = (prefix, label, levels) => levels.map((lv, i) => ({
    id: `${prefix}-${i}`,
    name: `${label} ${["I", "II", "III", "IV", "V"][i]}`,
    level: lv,
    iconIdx: i % FS_SKILL_ICONS.length
  }));

  return {
    groups: [
    { id: "weapon", name: "Weapon", masteries: [
      makeMastery("bicheon", "Bicheon", 30),
      makeMastery("heuksal", "Heuksal", 42),
      makeMastery("pacheon", "Pacheon", 18)]
    },
    { id: "force", name: "Force", masteries: [
      makeMastery("cold", "Cold", 25),
      makeMastery("light", "Light", 12),
      makeMastery("fire", "Fire", 0)]
    },
    { id: "recovery", name: "Recovery", masteries: [
      makeMastery("heal", "Heal", 8),
      makeMastery("buff", "Buff", 4),
      makeMastery("aura", "Aura", 0)]
    }]

  };
}

// ─── Long-press hook ─────────────────────────────────────────────────────────
// Returns handlers that fire onShort() on a normal tap/click and onLong() when
// the press is held >500ms or Shift is held when clicking with the mouse.

function useLongPress(onShort, onLong, ms = 500) {
  const timer = useRefFS(null);
  const fired = useRefFS(false);

  const start = useCallbackFS((e) => {
    fired.current = false;
    if (e.shiftKey) {// shift+click → long
      e.preventDefault?.();
      fired.current = true;
      onLong(e);
      return;
    }
    timer.current = setTimeout(() => {
      fired.current = true;
      onLong(e);
    }, ms);
  }, [onLong, ms]);

  const cancel = useCallbackFS(() => {
    if (timer.current) {clearTimeout(timer.current);timer.current = null;}
  }, []);

  const end = useCallbackFS((e) => {
    if (timer.current) {clearTimeout(timer.current);timer.current = null;}
    if (!fired.current) onShort(e);
  }, [onShort]);

  return {
    onPointerDown: start,
    onPointerUp: end,
    onPointerLeave: cancel,
    onPointerCancel: cancel
  };
}

// ─── Bits ────────────────────────────────────────────────────────────────────

function FsIconBtn({ children, onClick, disabled, title, kind = "ghost", ...rest }) {
  const styles = {
    ghost: {
      background: "var(--card)",
      border: "1px solid var(--line)",
      color: disabled ? "var(--text-mute)" : "var(--text)"
    },
    primary: {
      background: "linear-gradient(180deg, var(--brass-hi), var(--brass))",
      color: "var(--bg)",
      border: "none"
    },
    danger: {
      background: "transparent",
      border: "1px solid var(--line)",
      color: disabled ? "var(--text-mute)" : "var(--red, #e85a4a)"
    }
  }[kind];
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      title={title}
      {...rest}
      style={{
        all: "unset",
        cursor: disabled ? "not-allowed" : "pointer",
        opacity: disabled ? 0.4 : 1,
        ...styles,
        padding: "10px 14px",
        borderRadius: 10,
        fontWeight: 700, fontSize: 13,
        textAlign: "center",
        minWidth: 44, minHeight: 44,
        display: "inline-flex", alignItems: "center", justifyContent: "center",
        gap: 6,
        userSelect: "none"
      }}>
      {children}</button>);

}

// ─── Skill row ───────────────────────────────────────────────────────────────

function FsSkillRow({ skill, onChangeLevel, onShowInfo }) {
  const isMax = skill.level >= SKILL_LEVEL_MAX;
  const isMin = skill.level <= 0;

  const downBind = useLongPress(
    () => onChangeLevel(Math.max(0, skill.level - 1)),
    () => onChangeLevel(0)
  );
  const upBind = useLongPress(
    () => onChangeLevel(Math.min(SKILL_LEVEL_MAX, skill.level + 1)),
    () => onChangeLevel(SKILL_LEVEL_MAX)
  );

  return (
    <div className="fs-skill-row">
      <button
        className="fs-skill-trigger"
        onClick={onShowInfo}
        aria-label={skill.name}>
        
        <span className="fs-skill-icon">
          <img src={FS_SKILL_ICONS[skill.iconIdx]} alt="" />
        </span>
        <span className="fs-skill-meta">
          <span className="fs-skill-name">{skill.name}</span>
          <span className="fs-skill-level">
            <span className="fs-level-num">{skill.level}</span>
            <span style={{ color: "var(--text-mute)" }}>/</span>
            <span style={{ color: "var(--text-mute)" }}>{SKILL_LEVEL_MAX}</span>
            {isMax && <span className="fs-max-pill">MAX</span>}
          </span>
        </span>
      </button>
      <div className="fs-skill-controls">
        {/* down — hide when at 0 */}
        {!isMin &&
        <button className="fs-step-btn" {...downBind} title="Level down (hold for 0)">−</button>
        }
        {/* up — when at max, show "MAX" label instead */}
        {isMax ?
        <span className="fs-max-tag">MAX</span> :

        <button className="fs-step-btn primary" {...upBind} title="Level up (hold for max)">+</button>
        }
      </div>
    </div>);

}

// ─── Mastery section ─────────────────────────────────────────────────────────

function FsMasterySection({ series, onSkill, onShowInfo, onShowSeriesInfo }) {
  const hasProgress = series.skills.some((s) => s.level > 0);
  const [collapsed, setCollapsed] = useStateFS(!hasProgress);
  return (
    <section className={"fs-series" + (collapsed ? " is-collapsed" : "")}>
      <div className="fs-series-head" onClick={() => setCollapsed((c) => !c)}>
        <button
          className="fs-series-trigger"
          onClick={(e) => {e.stopPropagation();onShowSeriesInfo(series);}}>
          
          <span className="fs-series-glyph">{series.glyph}</span>
          <span className="fs-series-name">{series.name}</span>
        </button>
        <span className="fs-series-count">
          {series.skills.filter((s) => s.level > 0).length}/{series.skills.length}
        </span>
        <button
          className="fs-series-toggle"
          aria-label={collapsed ? "Expand" : "Collapse"}
          aria-expanded={!collapsed}
          onClick={(e) => {e.stopPropagation();setCollapsed((c) => !c);}}>
          
          <span className="fs-chevron">⌃</span>
        </button>
      </div>
      {!collapsed &&
      <div className="fs-series-body">
          {series.skills.map((s, i) =>
        <FsSkillRow
          key={s.id}
          skill={s}
          onChangeLevel={(lv) => onSkill(series.id, s.id, lv)}
          onShowInfo={() => onShowInfo(s)} />

        )}
        </div>
      }
    </section>);

}

// ─── Series info popover ─────────────────────────────────────────────────────

function FsSeriesInfo({ series, onClose }) {
  if (!series) return null;
  const leveled = series.skills.filter((s) => s.level > 0).length;
  const invested = series.skills.reduce((s, sk) => s + sk.level, 0);
  const cap = series.skills.length * SKILL_LEVEL_MAX;
  return (
    <div className="fs-info-bg" onClick={onClose}>
      <div className="fs-info" onClick={(e) => e.stopPropagation()}>
        <div className="fs-info-head">
          <span className="fs-info-icon fs-info-icon-glyph">{series.glyph}</span>
          <div>
            <div className="fs-info-name">{series.name}</div>
            <div className="fs-info-level">
              <b style={{ color: "var(--brass-hi)" }}>{leveled}</b> / {series.skills.length} skills unlocked
            </div>
          </div>
        </div>
        <div className="fs-info-body">
          <div className="fs-info-line">
            <span>Skills in series</span>
            <b>{series.skills.length}</b>
          </div>
          <div className="fs-info-line">
            <span>Points invested</span>
            <b>{invested} / {cap}</b>
          </div>
          <div className="fs-info-line">
            <span>Required mastery</span>
            <b>Lv 8</b>
          </div>
          <p className="fs-info-desc">
            A connected line of {series.name.replace(/ series$/i, "")} techniques. Leveling earlier
            skills in the chain unlocks the more powerful skills that follow.
          </p>
        </div>
        <button className="btn-primary fs-info-done" onClick={onClose}>Close</button>
      </div>
    </div>);

}

// ─── Skill info popover ──────────────────────────────────────────────────────

function FsSkillInfo({ skill, onClose }) {
  if (!skill) return null;
  return (
    <div className="fs-info-bg" onClick={onClose}>
      <div className="fs-info" onClick={(e) => e.stopPropagation()}>
        <div className="fs-info-head">
          <img className="fs-info-icon" src={FS_SKILL_ICONS[skill.iconIdx]} alt="" />
          <div>
            <div className="fs-info-name">{skill.name}</div>
            <div className="fs-info-level">
              Level <b style={{ color: "var(--brass-hi)" }}>{skill.level}</b> / {SKILL_LEVEL_MAX}
            </div>
          </div>
        </div>
        <div className="fs-info-body">
          <div className="fs-info-line">
            <span>Required mastery</span>
            <b>Lv 8</b>
          </div>
          <div className="fs-info-line">
            <span>SP cost (next level)</span>
            <b>3,240</b>
          </div>
          <div className="fs-info-line">
            <span>Cooldown</span>
            <b>4.5 s</b>
          </div>
          <p className="fs-info-desc">
            Strikes the target with a focused thrust, dealing physical damage and applying a brief stagger.
          </p>
        </div>
        <button className="btn-primary fs-info-done" onClick={onClose}>Close</button>
      </div>
    </div>);

}

// ─── Main planner ────────────────────────────────────────────────────────────

function SkillEditor({ kind, onClose }) {
  const [state, setState] = useStateFS(buildPlannerState);
  const [groupId, setGroupId] = useStateFS("weapon");
  const [masteryId, setMasteryId] = useStateFS("heuksal");
  const [infoSkill, setInfoSkill] = useStateFS(null);
  const [infoSeries, setInfoSeries] = useStateFS(null);

  const group = state.groups.find((g) => g.id === groupId);
  const mastery = group.masteries.find((m) => m.id === masteryId) ||
  group.masteries[0];

  // helpers to mutate state immutably
  const mutate = (fn) => setState((prev) => {
    const next = JSON.parse(JSON.stringify(prev));
    fn(next);
    return next;
  });

  const setMasteryLevel = (lv) => mutate((s) => {
    const g = s.groups.find((x) => x.id === groupId);
    const m = g.masteries.find((x) => x.id === masteryId);
    m.level = Math.max(0, Math.min(MASTERY_MAX, lv));
  });
  const setSkill = (seriesId, skillId, lv) => mutate((s) => {
    const g = s.groups.find((x) => x.id === groupId);
    const m = g.masteries.find((x) => x.id === masteryId);
    const sr = m.series.find((x) => x.id === seriesId);
    const sk = sr.skills.find((x) => x.id === skillId);
    sk.level = Math.max(0, Math.min(SKILL_LEVEL_MAX, lv));
  });
  const maxAllSkills = () => mutate((s) => {
    const g = s.groups.find((x) => x.id === groupId);
    const m = g.masteries.find((x) => x.id === masteryId);
    m.series.forEach((sr) => sr.skills.forEach((sk) => sk.level = SKILL_LEVEL_MAX));
  });
  const maxMastery = () => mutate((s) => {
    const g = s.groups.find((x) => x.id === groupId);
    const m = g.masteries.find((x) => x.id === masteryId);
    m.level = MASTERY_MAX;
  });
  const clearAll = () => mutate((s) => {
    const g = s.groups.find((x) => x.id === groupId);
    const m = g.masteries.find((x) => x.id === masteryId);
    m.level = 0;
    m.series.forEach((sr) => sr.skills.forEach((sk) => sk.level = 0));
  });

  // close on Esc
  useEffectFS(() => {
    const onKey = (e) => {if (e.key === "Escape") onClose();};
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  // lock body scroll while open
  useEffectFS(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {document.body.style.overflow = prev;};
  }, []);

  const isFuture = kind === "future";
  const tagClass = isFuture ? "fs-tag-future" : "fs-tag-current";
  const tagText = isFuture ? "PLANNING" : "CURRENT";

  // totals across the active mastery (for the summary chip)
  const skillsTotal = mastery.series.reduce((s, sr) =>
  s + sr.skills.reduce((ss, sk) => ss + sk.level, 0), 0);
  const skillsMax = mastery.series.reduce((s, sr) =>
  s + sr.skills.length * SKILL_LEVEL_MAX, 0);

  return (
    <div className="fs">
        {/* Top bar */}
        <div className="topbar">
          <div className="topbar-inner">
            <div className="brand">
              <div className="brand-mark">S</div>
              <span>Skill Planner</span>
            </div>
            <nav className="nav">
            </nav>
            <div className="top-actions">
              <button className="chars-pill">
                <span style={{ fontSize: 12, color: "var(--text-dim)" }}>Characters</span>
                <span className="count">3</span>
              </button>
            </div>
          </div>
        </div>

        {/* Body — scrolling area */}
        <div className="fs-body" style={{ textAlign: "left" }}>
         <div className="char-bar" style={{ width: "800px", maxWidth: "100%", margin: "0 auto 14px", textAlign: "left", justifyContent: "space-between", alignItems: "stretch" }}>
            <div className="char-bar-id">
              <div className="char-avatar">
                <FsChineseGlyph size={34} active />
              </div>
              <div className="char-bar-text">
                <h1 className="char-bar-name">BuckTBC</h1>
                <span className="char-bar-race">Chinese</span>
              </div>
            </div>
            <div className="char-bar-level">
              <span className="char-bar-level-label">Level&nbsp;Cap</span>
              <span className="char-bar-level-val">110</span>
            </div>
          </div>
         <div className="fs-panel" style={{ width: "800px", maxWidth: "100%", margin: "0 auto", alignItems: "stretch", justifyContent: "flex-start", flexDirection: "column" }}>
          {/* Panel title */}
          <div className="fs-panel-head">
            <h1 className="fs-panel-title">{kind === "future" ? "Future Skills" : "Current Skills"}</h1>
            <span className={"fs-panel-badge " + tagClass}>
              <span className="fs-panel-badge-dot"></span>
              {tagText}
            </span>
          </div>
          {/* Group + Mastery tabs */}
          <div className="fs-tabs" style={{ padding: "14px" }}>
            <div className="ro-tabs">
              {state.groups.map((g) =>
              <button key={g.id}
              className={"ro-tab" + (groupId === g.id ? " on" : "")}
              onClick={() => {
                setGroupId(g.id);
                const gr = state.groups.find((x) => x.id === g.id);
                setMasteryId(gr.masteries[0].id);
              }}>{g.name}</button>
              )}
            </div>
            <div className="ro-subtabs">
              {group.masteries.map((m) =>
              <button key={m.id}
              className={"ro-subtab" + (masteryId === m.id ? " on" : "")}
              onClick={() => setMasteryId(m.id)}>{m.name}</button>
              )}
            </div>
          </div>

          {/* Mastery summary + level controls */}
          <section className="fs-mastery" style={{ padding: "14px" }}>
            <div className="fs-mastery-info">
              <h2 className="fs-mastery-name">
                <img className="fs-mastery-icon" src="assets/mastery-icon.png" alt="" />
                {mastery.name}
                <span className="fs-mastery-sub"> · mastery</span>
              </h2>
              <div className="fs-mastery-stats">
                <span>
                  <span className="fs-stat-label">Mastery Lv</span>
                  <span className="fs-stat-val">{mastery.level}</span>
                  <span className="fs-stat-of">/{MASTERY_MAX}</span>
                </span>
                <span>
                  <span className="fs-stat-label">Skills</span>
                  <span className="fs-stat-val">{skillsTotal}</span>
                  <span className="fs-stat-of">/{skillsMax}</span>
                </span>
              </div>
            </div>
            <div className="fs-mastery-controls" style={{ height: "66px", padding: "10px 14px" }}>
              <FsIconBtn
                onClick={() => setMasteryLevel(mastery.level - 1)}
                disabled={mastery.level <= 0}
                title="Mastery level down">
                −</FsIconBtn>
              <div className="fs-mastery-bar">
                <div
                  className="fs-mastery-bar-fill"
                  style={{ width: `${mastery.level / MASTERY_MAX * 100}%` }} />
                
              </div>
              <FsIconBtn
                onClick={() => setMasteryLevel(mastery.level + 1)}
                disabled={mastery.level >= MASTERY_MAX}
                title="Mastery level up">
                +</FsIconBtn>
            </div>
          </section>

          {/* Bulk actions */}
          <div className="fs-actions" style={{ margin: "0px" }}>
            <FsIconBtn onClick={maxMastery} disabled={mastery.level >= MASTERY_MAX}>
              Max mastery
            </FsIconBtn>
            <FsIconBtn onClick={maxAllSkills}>Max skills</FsIconBtn>
            <FsIconBtn kind="danger" onClick={clearAll}>Clear all</FsIconBtn>
          </div>

          {/* Hint — above the skill series */}
          <p className="fs-hint" style={{ margin: "0px" }}>
            Hold + or − (or Shift-click on desktop) to jump to the max / 0 of a skill.
          </p>

          {/* Series + skills */}
          <div className="fs-series-list">
            {mastery.series.map((sr) =>
            <FsMasterySection
              key={sr.id}
              series={sr}
              onSkill={setSkill}
              onShowInfo={setInfoSkill}
              onShowSeriesInfo={setInfoSeries} />

            )}
          </div>

          {/* Actions — end of skill series section */}
          <div className="fs-section-sep"></div>
          <div className="fs-actions">
            <button className="btn-ghost" onClick={onClose} style={{ flex: 1, padding: "13px 16px" }}>
              Cancel
            </button>
            <button className="btn-primary" onClick={onClose} style={{ flex: 2, padding: "13px 16px" }}>Apply

            </button>
          </div>
         </div>
        </div>

      <FsSkillInfo skill={infoSkill} onClose={() => setInfoSkill(null)} />
      <FsSeriesInfo series={infoSeries} onClose={() => setInfoSeries(null)} />
    </div>);

}

window.SkillEditor = SkillEditor;