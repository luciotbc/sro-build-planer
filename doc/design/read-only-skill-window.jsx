// Read-only skills view used inside the home PlannerCard.
// Strips the game-themed window chrome from SkillWindow and presents the
// same data in a clean, modern, scannable card.
//
// Hierarchy displayed:
//   Mastery Types → Mastery → Mastery Level / Mastery Skills →
//     Mastery Series → Skill Row → Skill icon + level

const { useState: useStateRO } = React;

// Icons live in the assets/ folder (extracted earlier).
const RO_ICONS = [
  "assets/skill-a.png",
  "assets/skill-b.png",
  "assets/skill-c.png",
  "assets/skill-d.png",
  "assets/skill-e.png",
];

// Same hierarchy the fullscreen planner uses, so the two views stay in sync
// visually (groups, masteries, series).
const RO_GROUPS = [
  { id:"weapon",   name:"Weapon" },
  { id:"force",    name:"Force" },
  { id:"recovery", name:"Recovery" },
];
const RO_MASTERIES = {
  weapon: [
    { id:"bicheon", name:"Bicheon" },
    { id:"heuksal", name:"Heuksal" },
    { id:"pacheon", name:"Pacheon" },
  ],
  force: [
    { id:"cold",  name:"Cold" },
    { id:"light", name:"Light" },
    { id:"fire",  name:"Fire" },
  ],
  recovery: [
    { id:"heal", name:"Heal" },
    { id:"buff", name:"Buff" },
    { id:"aura", name:"Aura" },
  ],
};

// Sample series for the active mastery. Each skill carries its current level
// and its planned (target) level → rendered as "current → planned".
const RO_SERIES = [
  { id:"pierce",  name:"Pierce series",  glyph:"✦", skills:[[9,12],[9,12],[8,11],[6,9],[4,7]] },
  { id:"cyclone", name:"Cyclone series", glyph:"✸", skills:[[12,16],[10,14],[8,12],[6,10],[4,8]] },
  { id:"frost",   name:"Frost series",   glyph:"✺", skills:[[9,9],[7,9],[5,9],[3,7],[0,5]] },
  { id:"shadow",  name:"Shadow series",  glyph:"✹", skills:[[9,9],[7,9],[5,8],[3,6],[0,0]] },
];

const SKILL_MAX_RO = 42;

const ROMAN_RO = ["I", "II", "III", "IV", "V"];

function ReadOnlySkillWindow({ kind = "current" }){
  const [groupId, setGroupId] = useStateRO("weapon");
  const [masteryId, setMasteryId] = useStateRO("heuksal");
  const [infoSkill, setInfoSkill] = useStateRO(null);
  const [infoSeries, setInfoSeries] = useStateRO(null);
  const isFuture = kind === "future";

  const masteries = RO_MASTERIES[groupId] || [];
  const masteryName = (masteries.find(m => m.id === masteryId) || masteries[0])?.name || "";

  const skillsTotal = RO_SERIES.reduce(
    (s, sr) => s + sr.skills.reduce((ss, lv) => ss + lv[1], 0), 0);
  const skillsMaxTotal = RO_SERIES.length * 5 * SKILL_MAX_RO;
  const masteryCur = 92;
  const masteryPlan = 110;

  return (
    <div className="ro-skills">
      {/* MASTERY TYPES — top pills */}
      <div className="ro-tabs">
        {RO_GROUPS.map(g => {
          const on = groupId === g.id;
          return (
            <button key={g.id}
              className={"ro-tab" + (on ? " on" : "")}
              onClick={()=>{
                setGroupId(g.id);
                const ms = RO_MASTERIES[g.id];
                if (ms?.length) setMasteryId(ms[0].id);
              }}>{g.name}</button>
          );
        })}
      </div>

      {/* MASTERY — secondary pills */}
      <div className="ro-subtabs">
        {masteries.map(m => {
          const on = masteryId === m.id;
          return (
            <button key={m.id}
              className={"ro-subtab" + (on ? " on" : "")}
              onClick={()=>setMasteryId(m.id)}>{m.name}</button>
          );
        })}
      </div>

      {/* MASTERY LEVEL + MASTERY SKILLS summary */}
      <div className="ro-summary">
        <div className="ro-summary-left">
          <img className="ro-mastery-icon" src="assets/mastery-icon.png" alt="" />
          <span className="ro-summary-name">{masteryName}</span>
        </div>
        <div className="ro-summary-stats">
          <span>
            <span className="ro-summary-label">Lv</span>
            <span className="ro-summary-val"><span className="lv-cur">{masteryCur}</span><span className="lv-arrow"> → </span><span className="lv-plan">{masteryPlan}</span></span>
            <span className="ro-summary-of">/110</span>
          </span>
        </div>
      </div>

      {/* MASTERY SERIES → SKILL ROW → SKILL ICONS */}
      <div className="ro-series-list">
        {RO_SERIES.map(sr => (
          <div key={sr.id} className="ro-series">
            <div className="ro-skill-row">
              <button type="button" className="ro-series-icon" title={sr.name}
                onClick={()=>setInfoSeries({
                  glyph: sr.glyph,
                  name: sr.name,
                  skills: sr.skills.map(lv => ({ level: isFuture ? lv[1] : lv[0] })),
                })}
                style={{ cursor: "pointer", font: "inherit", color: "inherit" }}>{sr.glyph}</button>
              {sr.skills.map((lv, i) => {
                const cur = lv[0], plan = lv[1];
                const learned = plan > 0;
                const seriesLabel = sr.name.replace(/ series$/i, "");
                const showInfo = () => setInfoSkill({
                  name: `${seriesLabel} ${ROMAN_RO[i] || i + 1}`,
                  level: isFuture ? plan : cur,
                  iconIdx: i % RO_ICONS.length,
                });
                return (
                  <div key={i} className={"ro-skill" + (!learned ? " locked" : "")}>
                    <button type="button"
                      className="ro-skill-icon"
                      onClick={learned ? showInfo : undefined}
                      disabled={!learned}
                      style={{ cursor: learned ? "pointer" : "default", font: "inherit", color: "inherit" }}>
                      {learned && <img src={RO_ICONS[i % RO_ICONS.length]} alt=""/>}
                    </button>
                    <div className="ro-skill-level">
                      {learned ? (
                        <><span className="lv-cur">{cur}</span><span className="lv-arrow"> → </span><span className="lv-plan">{plan}</span></>
                      ) : "—"}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      {/* FOOT BAR — Skill points + Mastery level total + Required level */}
      <div className="ro-footer">
        <div className="ro-footer-row">
          <span className="ro-footer-label">Skill points</span>
          <span className="ro-footer-val">
            <span className="lv-cur">3,210,000</span><span className="ro-footer-delta">+3,230,000</span><span className="ro-footer-eq"> = </span><span className="lv-plan">6,440,000</span>
          </span>
        </div>
        <div className="ro-footer-row">
          <span className="ro-footer-label">Mastery level total</span>
          <span className="ro-footer-val">
            <span className="lv-cur">100</span><span className="ro-footer-delta">+75</span><span className="ro-footer-eq"> = </span><span className="lv-plan">175</span>
          </span>
        </div>
        <div className="ro-footer-row">
          <span className="ro-footer-label">Required level</span>
          <span className="ro-footer-val">
            <span className="lv-cur">92</span><span className="ro-footer-delta">+18</span><span className="ro-footer-eq"> = </span><span className="lv-plan">110</span>
          </span>
        </div>
      </div>

      {window.FsSkillInfo && <window.FsSkillInfo skill={infoSkill} onClose={()=>setInfoSkill(null)} />}
      {window.FsSeriesInfo && <window.FsSeriesInfo series={infoSeries} onClose={()=>setInfoSeries(null)} />}
    </div>
  );
}

window.ReadOnlySkillWindow = ReadOnlySkillWindow;
