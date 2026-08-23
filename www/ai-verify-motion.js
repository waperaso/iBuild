(() => {
  "use strict";

  const root = document.getElementById("aiVerifyMotion");
  if (!root) return;

  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const hudKicker = root.querySelector("[data-ai-hud-kicker]");
  const hudTitle = root.querySelector("[data-ai-hud-title]");
  const photoA = root.querySelector('[data-av="photoA"]');
  const photoB = root.querySelector('[data-av="photoB"]');
  const tagEl = root.querySelector('[data-av-field="tag"]');

  const copy = (key) => {
    const lang = document.documentElement.lang || "en";
    return window.IBUILD_I18N?.[lang]?.[key] ?? window.IBUILD_I18N?.en?.[key] ?? "";
  };

  let token = 0;
  let visible = false;

  const wait = (ms, t) =>
    new Promise((resolve) => {
      window.setTimeout(() => resolve(token === t), ms);
    });

  const hud = (kickerKey, titleKey) => {
    if (hudKicker) hudKicker.textContent = copy(kickerKey);
    if (hudTitle) hudTitle.textContent = copy(titleKey);
  };

  const setTag = (key) => {
    if (tagEl) tagEl.textContent = copy(key);
  };

  const resetUi = () => {
    root.classList.remove("is-checking", "is-verdict");
    if (photoA) photoA.classList.add("is-current");
    if (photoB) photoB.classList.remove("is-current");
    setTag("verify.visual.tagBaseline");
  };

  const showStatic = () => {
    resetUi();
    hud("verify.motion.phase3Kicker", "verify.motion.phase3Title");
    if (photoA) photoA.classList.remove("is-current");
    if (photoB) photoB.classList.add("is-current");
    setTag("verify.visual.tagFollowup");
    root.classList.add("is-checking", "is-verdict");
  };

  const playLoop = async (t) => {
    while (token === t && visible) {
      resetUi();
      hud("verify.motion.phase1Kicker", "verify.motion.phase1Title");
      if (!(await wait(900, t))) return;

      hud("verify.motion.phase2Kicker", "verify.motion.phase2Title");
      root.classList.add("is-checking");
      if (!(await wait(1900, t))) return;

      if (photoA) photoA.classList.remove("is-current");
      if (photoB) photoB.classList.add("is-current");
      setTag("verify.visual.tagFollowup");
      if (!(await wait(1100, t))) return;

      hud("verify.motion.phase3Kicker", "verify.motion.phase3Title");
      root.classList.add("is-verdict");
      if (!(await wait(3200, t))) return;
    }
  };

  const start = () => {
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

  window.addEventListener("resize", syncVisibility);

  const observe = () => {
    hud("verify.motion.phase1Kicker", "verify.motion.phase1Title");
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
    if (visible) start();
    else if (reduced) showStatic();
  }).observe(document.documentElement, { attributes: true, attributeFilter: ["lang"] });
})();
