// Skill Planner — responsive home page.
// Mobile-first + desktop breakpoint via CSS (see Home.html).
// Two skill windows visible (Current + Future). Open Planner is primary CTA;
// Save prompts login/register when guest.

const { useState: useStateH } = React;

// ─── Race glyphs ─────────────────────────────────────────────────────────────

function ChineseGlyph({ size = 22, active }) {
  const fg = active ? "#f4d878" : "#7a6a40";
  const bg = active ? "#8b1f1f" : "#2a1818";
  return (
    <svg viewBox="0 0 32 32" width={size} height={size} style={{ display: "block" }}>
      <circle cx="16" cy="16" r="13" fill={bg} stroke={fg} strokeWidth="1.5" />
      <path d="M16 7 Q10 12 12 18 Q14 22 16 24 Q18 22 20 18 Q22 12 16 7 Z" fill={fg} opacity="0.85" />
      <circle cx="16" cy="14" r="1.6" fill={bg} />
    </svg>);

}
function EuropeanGlyph({ size = 22, active }) {
  const fg = active ? "#f4d878" : "#7a6a40";
  const bg = active ? "#1f3a6b" : "#15243a";
  return (
    <svg viewBox="0 0 32 32" width={size} height={size} style={{ display: "block" }}>
      <path d="M6 7 L26 7 L26 18 Q26 24 16 28 Q6 24 6 18 Z" fill={bg} stroke={fg} strokeWidth="1.5" />
      <path d="M16 9 L16 25 M9 14 L23 14" stroke={fg} strokeWidth="2" strokeLinecap="round" />
    </svg>);

}
const RACES = [
{ id: "chinese", name: "Chinese", Icon: ChineseGlyph, accent: "#8b1f1f" },
{ id: "european", name: "European", Icon: EuropeanGlyph, accent: "#1f3a6b" }];

const LEVEL_CAPS = [
{ lv: 90, tier: "Classic" },
{ lv: 100, tier: "Legacy" },
{ lv: 110, tier: "Standard" },
{ lv: 120, tier: "High" },
{ lv: 130, tier: "Extreme" }];


function LockIcon({ size = 10, color = "currentColor" }) {
  return (
    <svg viewBox="0 0 12 12" width={size} height={size} style={{ display: "inline-block" }}>
      <rect x="2.5" y="5.5" width="7" height="5" rx="1" fill={color} />
      <path d="M4 5.5 V4 a2 2 0 0 1 4 0 V5.5" stroke={color} strokeWidth="1" fill="none" />
    </svg>);

}

// ─── Top bar ─────────────────────────────────────────────────────────────────

function TopBar({ loggedIn, user, onLogin, onOpenChars, charsCount, elevated }) {
  return (
    <div className="topbar" style={elevated ? { zIndex: 50 } : undefined}>
      <div className="topbar-inner">
        <div className="brand">
          <div className="brand-mark">S</div>
          <span>Skill Planner</span>
        </div>
        <nav className="nav"></nav>
        <div className="top-actions">
          {loggedIn ?
          <button className="chars-pill" onClick={onOpenChars}>
              <span style={{ fontSize: 12, color: "var(--text-dim)" }}>Characters</span>
              <span className="count">{charsCount}</span>
            </button> :

          <button className="btn-primary" onClick={onLogin}>Log in</button>
          }
        </div>
      </div>
    </div>);

}

// ─── Hero / build header (race + name + stats) ───────────────────────────────

function Hero({ race, buildName, stats }) {
  const raceInfo = RACES.find((r) => r.id === race) || RACES[0];
  return (
    <div className="hero-split">
      <section className="hero hero-character">
      <div className="hero-left">
        <div>
          <div className="char-bar" style={{ textAlign: "left" }}>
            <div className="char-bar-id">
              <div className="char-avatar">
                <raceInfo.Icon size={34} active />
              </div>
              <div className="char-bar-text">
                <h1 className="char-bar-name">{buildName}</h1>
                <span className="char-bar-race">{raceInfo.name}</span>
              </div>
            </div>
            <div className="char-bar-level">
              <span className="char-bar-level-label">Level&nbsp;Cap</span>
              <span className="char-bar-level-val">{stats.lvFuture}</span>
            </div>
          </div>
        </div>
      </div>
      </section>
    </div>);

}

function StatsSummary({ stats }) {
  return (
    <div className="stat-merged" style={{ fontSize: "12px" }} data-comment-anchor="9ffab4d869-div-132-7">
      <Stat label="Skill points" current={stats.spCurrent} future={stats.spFuture} format={(n) => n.toLocaleString()} />
      <Stat label="Mastery total" current={stats.masteryCurrent} future={stats.masteryFuture} />
      <Stat label="Required level" current={stats.lvCurrent} future={stats.lvFuture} />
    </div>);

}

function Stat({ label, current, future, format = (n) => n }) {
  const delta = typeof current === "number" && typeof future === "number" ?
  future - current : null;
  return (
    <div className="stat-line">
      <span className="stat-label" style={{ fontSize: "14px" }}>{label}</span>
      <span className="stat-eq">
        <span className="stat-val" style={{ color: "rgb(255, 255, 255)" }}>{format(current)}</span>
        {delta != null && delta !== 0 &&
        <>
          <span className="stat-op">+</span>
          <span className="stat-delta">{format(delta)}</span>
        </>
        }
        <span className="stat-op">=</span>
        <span className="stat-future">{format(future)}</span>
      </span>
    </div>);

}

// ─── Planner card (read-only skills + edit actions) ──────────────────────────

function PlannerCard({ kind }) {
  const isFuture = kind === "future";
  return (
    <div className={"planner-card" + (isFuture ? " future" : "")} style={{ borderColor: "rgb(38, 42, 51)", margin: "14px auto 0", width: "100%", maxWidth: "800px" }}>
      <div className="planner-head">
        <h2 className="planner-title">Skills</h2>
        <span className="legend-badge">
          <span className="legend-cur">Current</span>
          <span className="legend-arrow">→</span>
          <span className="legend-plan">Planned</span>
        </span>
      </div>
      <div className="planner-window-frame">
        <ReadOnlySkillWindow kind={kind} />
      </div>

      <div className="planner-actions">
        <button className="btn-ghost" style={{ flex: 1 }} onClick={() => {window.location.href = "skills_editor.html?kind=current";}}>
          Edit Current
        </button>
        <span className="planner-actions-arrow" aria-hidden="true">→</span>
        <button className="btn-primary" style={{ flex: 1 }} onClick={() => {window.location.href = "skills_editor.html?kind=future";}}>
          Edit Planned
        </button>
      </div>
    </div>);

}

// ─── Characters drawer ───────────────────────────────────────────────────────

function CharsDrawer({ open, onClose, chars, activeId, onSelect, onNew }) {
  if (!open) return null;
  return (
    <div className="drawer-bg" onClick={onClose}>
      <div className="drawer" onClick={(e) => e.stopPropagation()}>
        <div className="drawer-head">
          <div style={{ fontSize: 16, fontWeight: 700 }}>Your characters</div>
          <button className="icon-btn" onClick={onClose} aria-label="Close">×</button>
        </div>
        <div className="drawer-body">
          {chars.map((c) => {
            const race = RACES.find((r) => r.id === c.race);
            const on = activeId === c.id;
            return (
              <div key={c.id} className={"char-row" + (on ? " on" : "")}
              onClick={() => {onSelect(c.id);onClose();}}>
                <div className="swatch" style={{ background: race.accent + "33" }}>
                  <race.Icon size={24} active />
                </div>
                <div className="meta">
                  <div className="name">{c.name}</div>
                  <div className="sub">
                    <span>{race.name}</span>
                    <LockIcon size={9} />
                    <span>•</span>
                    <span>Lv {c.level}</span>
                    <span>•</span>
                    <span>{c.skills} skills</span>
                  </div>
                </div>
                {on && <span className="lock-pill" style={{ color: "var(--brass-hi)" }}>active</span>}
              </div>);

          })}
          <button className="char-row" onClick={onNew}
          style={{
            border: "1px dashed var(--line)", margin: "8px 4px",
            justifyContent: "center", color: "var(--text-dim)", fontWeight: 600, fontSize: 13
          }}>
            + New character
          </button>
        </div>
      </div>
    </div>);

}

// ─── Login modal (also handles guest-save prompt) ────────────────────────────

function LoginModal({ open, onClose, onLogin, mode = "login" }) {
  if (!open) return null;
  const isSavePrompt = mode === "save-prompt";
  return (
    <div className="modal-bg" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2>
          {isSavePrompt ? "Sign in to save your build" : "Sign in"}
        </h2>
        <p>
          {isSavePrompt ?
          "Your character is being planned locally. Sign in or create a free account to save it and access it from any device." :
          "Welcome back. Log in to manage your saved characters."}
        </p>
        <input className="build-name" placeholder="Email" type="email"
        style={{ marginBottom: 8 }} />
        <input className="build-name" placeholder="Password" type="password"
        style={{ marginBottom: 14 }} />
        <div className="modal-actions">
          <button className="btn-ghost" onClick={onClose}>
            {isSavePrompt ? "Keep planning" : "Cancel"}
          </button>
          <button className="btn-primary" onClick={onLogin}>
            {isSavePrompt ? "Sign in & save" : "Log in"}
          </button>
        </div>
        <p style={{ marginTop: 14, marginBottom: 0, fontSize: 11, textAlign: "center" }}>
          New here? <span className="ghost-link" style={{ color: "var(--brass-hi)" }}>Create an account</span>
        </p>
      </div>
    </div>);

}

// ─── Create-character modal ──────────────────────────────────────────────────

function CreateCharacter({ open, onClose, onStart, closable = true, initial }) {
  const [name, setName] = useStateH(initial?.name || "");
  const [race, setRace] = useStateH(initial?.race || "chinese");
  const [cap, setCap] = useStateH(initial?.cap || 110);
  if (!open) return null;
  return (
    <div className="cc-bg" onClick={closable ? onClose : undefined}>
      <div className="cc" onClick={(e) => e.stopPropagation()}>
        {closable &&
        <button className="cc-close icon-btn" onClick={onClose} aria-label="Close">×</button>
        }
        <h2 className="cc-heading">New character</h2>

        {/* name */}
        <div className="cc-field">
          <label className="cc-label">Character name</label>
          <input
            className="build-name"
            placeholder="My character"
            value={name}
            onChange={(e) => setName(e.target.value)}
            autoFocus />
        </div>

        {/* race */}
        <div className="cc-field">
          <label className="cc-label">Char type</label>
          <div className="cc-race-grid">
            {RACES.map((r) => {
              const on = race === r.id;
              return (
                <button key={r.id} className={"cc-race" + (on ? " on" : "")}
                onClick={() => setRace(r.id)}>
                  <span className="cc-race-glyph"><r.Icon size={26} active={on} /></span>
                  <span className="cc-race-text">
                    <span className="cc-race-name">{r.name}</span>
                    <span className="cc-race-sub">{on ? "Selected" : "Choose"}</span>
                  </span>
                </button>);

            })}
          </div>
        </div>

        {/* level cap */}
        <div className="cc-field">
          <label className="cc-label">Server level cap</label>
          <div className="cc-caps">
            {LEVEL_CAPS.map((c) => {
              const on = cap === c.lv;
              return (
                <button key={c.lv} className={"cc-cap" + (on ? " on" : "")}
                onClick={() => setCap(c.lv)}>
                  <span className="cc-cap-lv">{c.lv}</span>
                  <span className="cc-cap-tier">{c.tier}</span>
                </button>);

            })}
          </div>
        </div>

        <button className="btn-primary cc-start"
        onClick={() => onStart({ name: name.trim() || "My character", race, cap })}>
          Start Build
        </button>
      </div>
    </div>);

}

// ─── App ─────────────────────────────────────────────────────────────────────

const STARTER_CHARS = [
{ id: "c1", name: "BuckTBC", race: "chinese", level: 110, skills: 32 },
{ id: "c2", name: "Pacheon Glaiver", race: "chinese", level: 80, skills: 18 },
{ id: "c3", name: "Sword Knight", race: "european", level: 95, skills: 24 }];


function App() {
  const [loggedIn, setLoggedIn] = useStateH(false);
  const [chars, setChars] = useStateH(STARTER_CHARS);
  const [activeId, setActiveId] = useStateH("c1");
  const active = chars.find((c) => c.id === activeId) || chars[0];

  const [race, setRace] = useStateH(active.race);
  const [buildName, setBuildName] = useStateH(active.name);
  const [drawerOpen, setDrawerOpen] = useStateH(false);
  const [loginOpen, setLoginOpen] = useStateH(false);
  const [loginMode, setLoginMode] = useStateH("login");
  const [capLevel, setCapLevel] = useStateH(110);
  const [ccOpen, setCcOpen] = useStateH(!!window.__FIRST_ACCESS);
  const [ccClosable, setCcClosable] = useStateH(false);

  // Race lock — if the active character is one of the saved ones, race is locked.
  const raceLocked = loggedIn && chars.some((c) => c.id === activeId);

  const stats = {
    spCurrent: 3210000, spFuture: 6440000,
    masteryCurrent: 210, masteryFuture: 440,
    lvCurrent: 92, lvFuture: capLevel
  };

  const openCreate = () => {setDrawerOpen(false);setCcClosable(true);setCcOpen(true);};
  const startBuild = ({ name, race: r, cap }) => {
    setBuildName(name);
    setRace(r);
    setCapLevel(cap);
    setCcOpen(false);
  };

  const openLogin = () => {setLoginMode("login");setLoginOpen(true);};
  const onSave = () => {
    if (!loggedIn) {setLoginMode("save-prompt");setLoginOpen(true);return;}
    // (already logged in) — toast/persist
  };

  return (
    <>
      <TopBar
        loggedIn={loggedIn} user={null}
        onLogin={openLogin}
        onOpenChars={() => setDrawerOpen(true)}
        charsCount={chars.length}
        elevated={ccOpen} />
      

      <div className="home-body">
        <Hero
          race={race}
          buildName={buildName}
          stats={stats} />

        <PlannerCard kind="future" data-comment-anchor="8925fc423e-span-174-11" />

        <div className="planner-card summary-card" style={{ margin: "14px auto 0", maxWidth: "800px", width: "100%" }}>
          <div className="planner-head">
            <h2 className="planner-title">Summary</h2>
          </div>
          <StatsSummary stats={stats} />
        </div>

        <div className="desktop-cta" style={{ margin: "18px auto 0", maxWidth: "800px", width: "100%" }}>
          <a className="ghost-link" onClick={() => setDrawerOpen(true)}>
            {chars.length} saved character{chars.length === 1 ? "" : "s"}
          </a>
          <div style={{ flex: 1 }} />
          <button className="btn-primary" onClick={onSave}>Save character</button>
        </div>
      </div>

      {/* Mobile sticky action bar */}
      <div className="action-bar">
        <button className="action-bar-chars" onClick={() => setDrawerOpen(true)}>
          <CharsIcon />
          <span>{chars.length}</span>
        </button>
        <button className="btn-primary" style={{ flex: 1 }} onClick={onSave}>Save</button>
      </div>

      <CharsDrawer
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        chars={chars}
        activeId={activeId}
        onSelect={(id) => {
          setActiveId(id);
          const c = chars.find((x) => x.id === id);
          if (c) {setRace(c.race);setBuildName(c.name);}
        }}
        onNew={openCreate} />
      

      <CreateCharacter
        open={ccOpen}
        closable={ccClosable}
        initial={{ name: ccClosable ? "" : buildName, race, cap: capLevel }}
        onClose={() => setCcOpen(false)}
        onStart={startBuild} />


      <LoginModal
        open={loginOpen}
        onClose={() => setLoginOpen(false)}
        mode={loginMode}
        onLogin={() => {setLoggedIn(true);setLoginOpen(false);}} />
    </>);

}

function CharsIcon() {
  return (
    <svg viewBox="0 0 16 16" width="14" height="14">
      <circle cx="5" cy="6" r="2.5" fill="currentColor" />
      <path d="M1 14 a4 4 0 0 1 8 0" fill="currentColor" />
      <circle cx="11" cy="6" r="2" fill="currentColor" opacity="0.5" />
      <path d="M8 14 a3 3 0 0 1 7 0" fill="currentColor" opacity="0.5" />
    </svg>);

}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);