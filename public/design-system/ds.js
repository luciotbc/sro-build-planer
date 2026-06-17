/* =============================================================================
   SRO Lab — Design System reference page behaviour
   Three jobs only: load+tint code panes, switch code tabs / copy, scroll TOC.
   ============================================================================= */
(function () {
  const esc = (s) =>
    s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

  // Light, comment-only tinting (mono stays readable; no full tokenizer).
  function tint(escaped, lang) {
    let out = escaped;
    if (lang === "erb" || lang === "html") {
      out = out.replace(/(&lt;%#[\s\S]*?%&gt;)/g, '<span class="c-com">$1</span>');
      out = out.replace(/(&lt;\/?[a-zA-Z][\w-]*)/g, '<span class="c-tag">$1</span>');
    } else if (lang === "css") {
      out = out.replace(/(\/\*[\s\S]*?\*\/)/g, '<span class="c-com">$1</span>');
    } else if (lang === "js") {
      out = out.replace(/(\/\/[^\n]*)/g, '<span class="c-com">$1</span>');
    }
    return out;
  }

  async function loadCode(el) {
    const code = el.querySelector("code");
    const lang = el.getAttribute("data-lang") || "erb";
    // Inline panes already carry their text; fetched panes pull a project file.
    if (el.hasAttribute("data-inline")) {
      code.dataset.raw = code.textContent;
      code.innerHTML = tint(esc(code.textContent), lang);
      return;
    }
    try {
      const text = (await (await fetch(el.getAttribute("data-src"))).text()).replace(/\s+$/, "");
      code.dataset.raw = text;
      code.innerHTML = tint(esc(text), lang);
    } catch (e) {
      code.textContent = "// Could not load " + el.getAttribute("data-src");
    }
  }

  function initCodeBlock(block) {
    const panes = [...block.querySelectorAll(".code-pane")];
    const tabs = [...block.querySelectorAll(".code-tab")];
    const path = block.querySelector(".code-path");
    panes.forEach(loadCode);
    tabs.forEach((tab, i) => {
      tab.addEventListener("click", () => {
        tabs.forEach((t) => t.classList.remove("on"));
        panes.forEach((p) => p.classList.remove("on"));
        tab.classList.add("on");
        panes[i].classList.add("on");
        if (path) path.textContent = panes[i].getAttribute("data-src") || "";
      });
    });
    const copy = block.querySelector(".copy-btn");
    if (copy) {
      copy.addEventListener("click", async () => {
        const active = block.querySelector(".code-pane.on code") || block.querySelector(".code-pane code");
        try {
          await navigator.clipboard.writeText(active.dataset.raw || active.textContent);
          copy.textContent = "Copied ✓";
          copy.classList.add("ok");
          setTimeout(() => { copy.textContent = "Copy"; copy.classList.remove("ok"); }, 1400);
        } catch (e) {}
      });
    }
  }

  document.querySelectorAll(".code").forEach(initCodeBlock);

  // Color swatches, grouped exactly like the colour briefing.
  const SWATCHES = [
    ["Marca", [
      ["Brass", "bg-brass", "#d4a847"],
      ["Brass Hi", "bg-brass-hi", "#f4d878"],
      ["Brass Dark", "from-…-[#6b4a18]", "#6b4a18"],
    ]],
    ["Superfícies", [
      ["Background", "bg-bg", "#0c0e12"],
      ["Card", "bg-card", "#15181f"],
      ["Card Hi", "bg-card-hi", "#1c2029"],
      ["Line", "border-line", "#262a33"],
    ]],
    ["Texto", [
      ["Text", "text-text", "#e6e8ec"],
      ["Text Dim", "text-text-dim", "#8b919e"],
      ["Text Mute", "text-text-mute", "#5c6270"],
    ]],
    ["Funcionais", [
      ["Blue", "text-blue", "#4ea3ff"],
      ["Red", "text-red", "#e85a4a"],
      ["Green", "text-green", "#38b676"],
    ]],
  ];
  const host = document.getElementById("swatches");
  if (host) {
    host.innerHTML = SWATCHES.map(([group, items]) => `
      <div class="swatch-group">
        <div class="swatch-group-label">${group}</div>
        <div class="swatch-grid">
          ${items.map(([name, util, hex]) => `
            <div class="swatch">
              <div class="swatch-chip" style="background:${hex}"></div>
              <div class="swatch-meta">
                <span class="swatch-name">${name}</span>
                <span class="swatch-util">${util}</span>
                <span class="swatch-hex">${hex}</span>
              </div>
            </div>`).join("")}
        </div>
      </div>`).join("");
  }

  // Smooth-scroll the sticky section index.
  document.querySelectorAll('.toc a[href^="#"]').forEach((a) => {
    a.addEventListener("click", (e) => {
      const t = document.querySelector(a.getAttribute("href"));
      if (t) { e.preventDefault(); window.scrollTo({ top: t.offsetTop - 96, behavior: "smooth" }); }
    });
  });
})();
