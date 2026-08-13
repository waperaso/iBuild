(() => {
  "use strict";

  const root = document.getElementById("aiMotion");
  if (!root) return;

  const SCENARIOS = ["home", "office", "rent"];
  const CRM_VALUES = {
    home: { metrics: [12, 28, 69], scores: [86, 58, 31] },
    office: { metrics: [8, 5, 82], scores: [91, 73, 24] },
    rent: { metrics: [14, 9, 76], scores: [89, 64, 28] },
  };
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const queryEl = root.querySelector("[data-ai-query]");
  const ghostEl = root.querySelector("[data-ai-ghost]");
  const caretEl = root.querySelector("[data-ai-caret]");
  const cursor = root.querySelector("[data-ai-cursor]");
  const hudKicker = root.querySelector("[data-ai-hud-kicker]");
  const hudTitle = root.querySelector("[data-ai-hud-title]");
  const hotEl = root.querySelector("[data-ai-hot]");
  const warmEl = root.querySelector("[data-ai-warm]");
  const readyEl = root.querySelector("[data-ai-ready]");
  const tabEl = root.querySelector("[data-ai-tab]");
  const searchEl = root.querySelector("[data-ai-search]");
  const leadEl = root.querySelector("[data-ai-lead]");
  const leadScoreEls = root.querySelectorAll("[data-ai-lead-score]");

  const copy = (key) => {
    const lang = document.documentElement.lang || "en";
    return window.IBUILD_I18N?.[lang]?.[key] ?? window.IBUILD_I18N?.en?.[key] ?? "";
  };

  let token = 0;
  let visible = false;
  let scenarioIndex = 0;
  let currentScenario = SCENARIOS[0];

  const scenarioCopy = (field) => copy(`ai.visual.scenario.${currentScenario}.${field}`);

  const fullQuery = () => `${scenarioCopy("query")}${scenarioCopy("ghost")}`;

  const applyScenario = (id) => {
    currentScenario = id;
    root.dataset.scenario = id;
    root.querySelectorAll("[data-ai-field]").forEach((el) => {
      const text = scenarioCopy(el.dataset.aiField);
      if (text) el.textContent = text;
    });
    const values = CRM_VALUES[id];
    if (hotEl) hotEl.textContent = String(values.metrics[0]);
    if (warmEl) warmEl.textContent = String(values.metrics[1]);
    if (readyEl) readyEl.textContent = `${values.metrics[2]}%`;
    leadScoreEls.forEach((el, index) => {
      el.textContent = String(values.scores[index]);
    });
  };

  const wait = (ms, t) =>
    new Promise((resolve) => {
      window.setTimeout(
        () => resolve(token === t && !root.hasAttribute("data-freeze")),
        ms
      );
    });

  const hud = (kickerKey, titleKey) => {
    if (hudKicker) hudKicker.textContent = copy(kickerKey);
    if (hudTitle) hudTitle.textContent = copy(titleKey);
  };

  const setScene = (name) => {
    root.dataset.scene = name;
  };

  const moveCursor = (el, extraX = 0, extraY = 0) => {
    if (!cursor || !el) return;
    const canvas = root.getBoundingClientRect();
    const box = el.getBoundingClientRect();
    const x = box.left - canvas.left + box.width * 0.72 + extraX;
    const y = box.top - canvas.top + box.height * 0.55 + extraY;
    cursor.style.transform = `translate(${x}px, ${y}px)`;
  };

  const showCursor = (on) => {
    if (!cursor) return;
    cursor.classList.toggle("is-on", Boolean(on));
  };

  const countUp = (el, to, t, suffix = "") => {
    if (!el) return;
    const start = performance.now();
    const dur = 720;
    const tick = (now) => {
      if (token !== t) return;
      const p = Math.min(1, (now - start) / dur);
      const eased = 1 - (1 - p) ** 3;
      el.textContent = `${Math.round(to * eased)}${suffix}`;
      if (p < 1) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  };

  const resetUi = () => {
    if (queryEl) queryEl.textContent = "";
    if (ghostEl) ghostEl.textContent = "";
    if (caretEl) caretEl.classList.remove("is-on");
    showCursor(false);
    root.classList.remove(
      "is-typed",
      "is-ghost",
      "is-tab",
      "is-chips",
      "is-thinking",
      "is-results",
      "is-metrics",
      "is-leads",
      "is-crm-msg"
    );
  };

  const showStatic = () => {
    applyScenario(SCENARIOS[0]);
    setScene("bridge");
    hud("ai.motion.bridgeKicker", "ai.motion.bridgeTitle");
    if (queryEl) queryEl.textContent = fullQuery();
    if (ghostEl) ghostEl.textContent = "";
    root.classList.add("is-typed", "is-chips", "is-results", "is-metrics", "is-leads", "is-crm-msg");
    showCursor(false);
  };

  const typeText = async (el, text, t, speed = 34) => {
    if (!el) return;
    el.textContent = "";
    root.classList.add("is-typed");
    for (let i = 0; i < text.length; i += 1) {
      if (token !== t) return;
      el.textContent = text.slice(0, i + 1);
      await wait(speed, t);
    }
  };

  const playLoop = async (t) => {
    while (token === t && visible && !root.hasAttribute("data-freeze")) {
      resetUi();
      applyScenario(SCENARIOS[scenarioIndex % SCENARIOS.length]);
      scenarioIndex += 1;

      setScene("search");
      hud("ai.motion.searchKicker", "ai.motion.searchTitle");
      if (!(await wait(380, t))) return;

      showCursor(true);
      if (searchEl) moveCursor(searchEl, -24, 0);
      if (caretEl) caretEl.classList.add("is-on");
      if (!(await wait(220, t))) return;

      await typeText(queryEl, scenarioCopy("query"), t);
      if (token !== t) return;

      if (ghostEl) ghostEl.textContent = scenarioCopy("ghost");
      root.classList.add("is-ghost");
      if (!(await wait(480, t))) return;

      if (tabEl) moveCursor(tabEl);
      root.classList.add("is-tab");
      if (!(await wait(420, t))) return;

      if (queryEl) queryEl.textContent = fullQuery();
      if (ghostEl) ghostEl.textContent = "";
      root.classList.remove("is-ghost", "is-tab");
      if (caretEl) caretEl.classList.remove("is-on");
      showCursor(false);

      root.classList.add("is-thinking");
      if (!(await wait(700, t))) return;
      root.classList.add("is-chips", "is-results");
      if (!(await wait(2200, t))) return;

      setScene("bridge");
      hud("ai.motion.bridgeKicker", "ai.motion.bridgeTitle");
      if (!(await wait(2000, t))) return;

      setScene("crm");
      hud("ai.motion.crmKicker", "ai.motion.crmTitle");
      const crmValues = CRM_VALUES[currentScenario].metrics;
      if (hotEl) hotEl.textContent = "0";
      if (warmEl) warmEl.textContent = "0";
      if (readyEl) readyEl.textContent = "0%";
      if (!(await wait(360, t))) return;
      root.classList.add("is-metrics");
      countUp(hotEl, crmValues[0], t);
      countUp(warmEl, crmValues[1], t);
      countUp(readyEl, crmValues[2], t, "%");
      if (!(await wait(700, t))) return;
      root.classList.add("is-leads");
      if (leadEl) {
        showCursor(true);
        moveCursor(leadEl, 40, 0);
      }
      if (!(await wait(900, t))) return;
      showCursor(false);
      root.classList.add("is-crm-msg");
      if (!(await wait(4200, t))) return;
    }
  };

  const start = () => {
    if (root.hasAttribute("data-freeze")) return;
    token += 1;
    const t = token;
    if (reduced) {
      showStatic();
      return;
    }
    playLoop(t);
  };

  const stop = () => {
    token += 1;
  };

  const isInView = () => {
    const rect = root.getBoundingClientRect();
    return rect.bottom > 80 && rect.top < window.innerHeight - 80;
  };

  const observer = new IntersectionObserver(
    (entries) => {
      const nowVisible = Boolean(entries[0]?.isIntersecting);
      if (nowVisible === visible) return;
      visible = nowVisible;
      if (visible) start();
      else stop();
    },
    { threshold: 0.18 }
  );

  const syncVisibility = () => {
    const nowVisible = isInView();
    if (nowVisible === visible) return;
    visible = nowVisible;
    if (visible) start();
    else stop();
  };

  window.addEventListener("resize", () => {
    syncVisibility();
    if (!visible || reduced) return;
    if (root.dataset.scene === "search" && searchEl) moveCursor(searchEl, -24, 0);
    if (root.dataset.scene === "crm" && leadEl) moveCursor(leadEl, 40, 0);
  });

  const observe = () => {
    applyScenario(SCENARIOS[0]);
    observer.observe(root);
    syncVisibility();
  };

  if (document.body.classList.contains("is-ready")) {
    observe();
  } else {
    const readyWatch = new MutationObserver(() => {
      if (!document.body.classList.contains("is-ready")) return;
      readyWatch.disconnect();
      observe();
    });
    readyWatch.observe(document.body, { attributes: true, attributeFilter: ["class"] });
  }

  new MutationObserver(() => {
    applyScenario(currentScenario);
    if (visible) start();
    else if (reduced) showStatic();
  }).observe(document.documentElement, { attributes: true, attributeFilter: ["lang"] });
})();
