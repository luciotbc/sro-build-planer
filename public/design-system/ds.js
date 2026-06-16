/* SRO Lab DS reference — code loading, tabs, copy buttons */
(function () {
  const esc = (s) =>
    s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

  // very light tinting: full-line comments + erb/quoted strings, mono only
  function tint(escaped, lang) {
    let out = escaped;
    if (lang === "erb" || lang === "html") {
      out = out.replace(/(&lt;%#[\s\S]*?%&gt;)/g, '<span class="c-com">$1</span>');
      out = out.replace(/(&lt;\/?[a-zA-Z][\w-]*)/g, '<span class="c-tag">$1</span>');
    } else if (lang === "css") {
      out = out.replace(/(\/\*[\s\S]*?\*\/)/g, '<span class="c-com">$1</span>');
    } else if (lang === "js" || lang === "rb") {
      out = out.replace(/(\/\/[^\n]*)/g, '<span class="c-com">$1</span>');
    }
    return out;
  }

  async function loadCode(el) {
    const src = el.getAttribute("data-src");
    const lang = el.getAttribute("data-lang") || "erb";
    const code = el.querySelector("code");
    if (el.hasAttribute("data-inline")) {
      // already has text content authored inline; just tint + store raw
      code.dataset.raw = code.textContent;
      code.innerHTML = tint(esc(code.textContent), lang);
      return;
    }
    try {
      const res = await fetch(src);
      let text = await res.text();
      text = text.replace(/\s+$/, "");
      code.dataset.raw = text;
      code.innerHTML = tint(esc(text), lang);
    } catch (e) {
      code.textContent = "// Could not load " + src;
    }
  }

  function initCodeBlock(block) {
    const panes = [...block.querySelectorAll(".code-pane")];
    const tabs = [...block.querySelectorAll(".code-tab")];
    panes.forEach((p) => loadCode(p));
    tabs.forEach((tab, i) => {
      tab.addEventListener("click", () => {
        tabs.forEach((t) => t.classList.remove("on"));
        panes.forEach((p) => p.classList.remove("on"));
        tab.classList.add("on");
        panes[i].classList.add("on");
        const path = block.querySelector(".code-path");
        if (path) path.textContent = panes[i].getAttribute("data-src") || "";
      });
    });
    const copy = block.querySelector(".copy-btn");
    if (copy) {
      copy.addEventListener("click", async () => {
        const active = block.querySelector(".code-pane.on code") || block.querySelector(".code-pane code");
        try {
          await navigator.clipboard.writeText(active.dataset.raw || active.textContent);
          const old = copy.textContent;
          copy.textContent = "Copied ✓";
          copy.classList.add("ok");
          setTimeout(() => { copy.textContent = old; copy.classList.remove("ok"); }, 1400);
        } catch (e) {}
      });
    }
  }

  document.querySelectorAll(".code").forEach(initCodeBlock);

  // smooth-scroll TOC + active highlight
  document.querySelectorAll('.toc a[href^="#"]').forEach((a) => {
    a.addEventListener("click", (e) => {
      const t = document.querySelector(a.getAttribute("href"));
      if (t) { e.preventDefault(); window.scrollTo({ top: t.offsetTop - 96, behavior: "smooth" }); }
    });
  });
})();
