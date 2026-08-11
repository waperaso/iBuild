(() => {
  "use strict";

  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const header = document.querySelector("[data-header]");
  const menuToggle = document.querySelector("[data-menu-toggle]");
  const mobileMenu = document.querySelector("[data-mobile-menu]");
  const navLinks = [...document.querySelectorAll(".desktop-nav a")];
  const sections = [...document.querySelectorAll("main section[id]")];

  const STORAGE_THEME = "ibuild-theme";
  const STORAGE_LANG = "ibuild-lang";
  const THEME_COLORS = { light: "#E4E7EB", dark: "#0A1F35" };
  const LOGO = {
    light: "assets/brand/ibuild-logo.jpg",
    dark: "assets/brand/ibuild-logo-dark.png"
  };

  const resolveAppUrls = () => {
    const host = window.location.hostname;
    const protocol = window.location.protocol;
    const isIp = /^\d+\.\d+\.\d+\.\d+$/.test(host);
    const isLocal = host === "localhost" || host === "127.0.0.1";

    if (isIp || isLocal) {
      return {
        b2c: `${protocol}//${host}:8081/`,
        b2b: `${protocol}//${host}:8080/`
      };
    }

    return {
      b2c: "https://app.ibuild.uz/",
      b2b: "https://admin.ibuild.uz/"
    };
  };

  let appUrls = resolveAppUrls();

  const appHref = (target) => (target === "b2b" ? appUrls.b2b : appUrls.b2c);

  const wireAppLinks = () => {
    appUrls = resolveAppUrls();
    document.querySelectorAll("[data-app-link]").forEach((link) => {
      const target = link.dataset.appLink;
      if (target !== "b2c" && target !== "b2b") return;
      link.setAttribute("href", appHref(target));
      link.setAttribute("target", "_blank");
      link.setAttribute("rel", "noopener noreferrer");
      link.removeAttribute("aria-disabled");
    });

    document.querySelectorAll(".gateway-url").forEach((el) => {
      const card = el.closest("[data-app-link]");
      if (!card) return;
      const href = appHref(card.dataset.appLink);
      try {
        el.textContent = new URL(href).host;
      } catch (_) {
        el.textContent = href.replace(/^https?:\/\//, "").replace(/\/$/, "");
      }
    });
  };

  const navigateAppLink = (link) => {
    const target = link?.dataset?.appLink;
    if (target !== "b2c" && target !== "b2b") return;
    const opened = window.open(appHref(target), "_blank");
    if (opened) opened.opener = null;
  };

  const initAppLinkNavigation = () => {
    wireAppLinks();
    document.addEventListener("click", (event) => {
      const link = event.target.closest("[data-app-link]");
      if (!link) return;
      const target = link.dataset.appLink;
      if (target !== "b2c" && target !== "b2b") return;
      const href = link.getAttribute("href");
      if (!href || href === "#" || href.endsWith("#")) {
        event.preventDefault();
        navigateAppLink(link);
        return;
      }
      closeMenu();
    });
  };

  let currentLang = "en";
  let currentTheme = "light";
  let activeProcess = 0;
  let processTimer = null;

  const t = (key) => window.IBUILD_I18N?.[currentLang]?.[key] ?? window.IBUILD_I18N?.en?.[key] ?? key;

  const applyLanguage = (lang) => {
    if (!window.IBUILD_I18N?.[lang]) lang = "en";
    currentLang = lang;
    localStorage.setItem(STORAGE_LANG, lang);
    document.documentElement.lang = lang;

    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.dataset.i18n;
      if (key) el.textContent = t(key);
    });

    document.querySelectorAll("[data-i18n-html]").forEach((el) => {
      const key = el.dataset.i18nHtml;
      if (key) el.innerHTML = t(key);
    });

    document.querySelectorAll("[data-i18n-aria]").forEach((el) => {
      const key = el.dataset.i18nAria;
      if (key) el.setAttribute("aria-label", t(key));
    });

    document.title = t("meta.title");
    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) metaDesc.setAttribute("content", t("meta.description"));

    document.querySelectorAll(".lang-btn").forEach((btn) => {
      btn.setAttribute("aria-pressed", String(btn.dataset.lang === lang));
    });

    activateProcessStep(activeProcess);

    wireAppLinks();
  };

  const applyTheme = (theme) => {
    if (theme !== "light" && theme !== "dark") theme = "light";
    currentTheme = theme;
    localStorage.setItem(STORAGE_THEME, theme);
    document.documentElement.setAttribute("data-theme", theme);

    const metaTheme = document.querySelector('meta[name="theme-color"]');
    if (metaTheme) metaTheme.setAttribute("content", THEME_COLORS[theme]);

    document.querySelectorAll("[data-logo]").forEach((img) => {
      img.src = LOGO[theme];
    });

    document.querySelectorAll("[data-theme-toggle]").forEach((btn) => {
      btn.setAttribute("aria-pressed", String(theme === "dark"));
    });
  };

  const initPreferences = () => {
    const savedTheme = localStorage.getItem(STORAGE_THEME);
    const savedLang = localStorage.getItem(STORAGE_LANG);
    applyTheme(savedTheme === "dark" ? "dark" : "light");
    applyLanguage(savedLang === "ru" || savedLang === "uz" ? savedLang : "en");
  };

  document.querySelectorAll(".lang-btn").forEach((btn) => {
    btn.addEventListener("click", () => applyLanguage(btn.dataset.lang));
  });

  document.querySelectorAll("[data-theme-toggle]").forEach((btn) => {
    btn.addEventListener("click", () => {
      applyTheme(currentTheme === "light" ? "dark" : "light");
    });
  });

  const setHeaderState = () => {
    header?.classList.toggle("is-scrolled", window.scrollY > 24);
  };

  setHeaderState();
  window.addEventListener("scroll", setHeaderState, { passive: true });

  const closeMenu = () => {
    if (!menuToggle || !mobileMenu) return;
    menuToggle.setAttribute("aria-expanded", "false");
    menuToggle.setAttribute("aria-label", t("a11y.openNav"));
    mobileMenu.setAttribute("aria-hidden", "true");
    document.body.classList.remove("menu-open");
  };

  menuToggle?.addEventListener("click", () => {
    const willOpen = menuToggle.getAttribute("aria-expanded") !== "true";
    menuToggle.setAttribute("aria-expanded", String(willOpen));
    menuToggle.setAttribute("aria-label", t(willOpen ? "a11y.closeNav" : "a11y.openNav"));
    mobileMenu?.setAttribute("aria-hidden", String(!willOpen));
    document.body.classList.toggle("menu-open", willOpen);
  });

  mobileMenu?.querySelectorAll(".mobile-nav-link, .mobile-app-link, [data-app-link]").forEach((link) => link.addEventListener("click", closeMenu));
  window.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeMenu();
  });

  const revealElements = document.querySelectorAll(".reveal");
  let revealObserver = null;

  const initRevealAnimations = () => {
    if (reducedMotion || !("IntersectionObserver" in window)) {
      revealElements.forEach((element) => element.classList.add("is-visible"));
      return;
    }

    revealObserver = new IntersectionObserver(
      (entries, observer) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -5% 0px" }
    );

    revealElements.forEach((element) => revealObserver.observe(element));
  };

  const waitForPageAssets = () => {
    const fontsReady = document.fonts?.ready ?? Promise.resolve();
    const images = [...document.querySelectorAll(".site-page img")].map((img) => {
      if (img.complete) return Promise.resolve();
      return new Promise((resolve) => {
        img.addEventListener("load", resolve, { once: true });
        img.addEventListener("error", resolve, { once: true });
      });
    });

    return Promise.all([fontsReady, ...images]);
  };

  if ("IntersectionObserver" in window) {
    const sectionObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          navLinks.forEach((link) => {
            link.classList.toggle("is-active", link.getAttribute("href") === `#${entry.target.id}`);
          });
        });
      },
      { rootMargin: "-40% 0px -52% 0px", threshold: 0 }
    );

    sections.forEach((section) => sectionObserver.observe(section));
  }

  const countElements = document.querySelectorAll("[data-count]");

  const animateCount = (element) => {
    const target = Number(element.dataset.count);
    if (!Number.isFinite(target)) return;
    if (reducedMotion) {
      element.textContent = String(target);
      return;
    }

    const duration = 1200;
    const start = performance.now();

    const tick = (now) => {
      const progress = Math.min((now - start) / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 4);
      element.textContent = String(Math.round(target * eased));
      if (progress < 1) requestAnimationFrame(tick);
    };

    requestAnimationFrame(tick);
  };

  if ("IntersectionObserver" in window) {
    const countObserver = new IntersectionObserver(
      (entries, observer) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          animateCount(entry.target);
          observer.unobserve(entry.target);
        });
      },
      { threshold: 0.7 }
    );

    countElements.forEach((element) => countObserver.observe(element));
  } else {
    countElements.forEach(animateCount);
  }

  const processSteps = [...document.querySelectorAll("[data-step]")];
  const processPanels = [...document.querySelectorAll("[data-panel]")];
  const processCopy = document.querySelector("[data-process-copy]");
  const processRail = document.querySelector(".process-rail i");

  const getProcessContent = () => window.IBUILD_PROCESS?.[currentLang] ?? window.IBUILD_PROCESS.en;

  const activateProcessStep = (index) => {
    if (!processSteps[index] || !processPanels[index] || !processCopy) return;

    processSteps.forEach((step, stepIndex) => {
      step.classList.toggle("is-active", stepIndex === index);
      step.setAttribute("aria-pressed", String(stepIndex === index));
    });
    processPanels.forEach((panel, panelIndex) => panel.classList.toggle("is-active", panelIndex === index));
    if (processRail) processRail.style.width = `${(index / Math.max(processSteps.length - 1, 1)) * 100}%`;

    const content = getProcessContent()[index];
    if (!content) return;

    processCopy.innerHTML = `
      <span class="micro-label">${content.label}</span>
      <h3>${content.title}</h3>
      <p>${content.text}</p>
      <ul>${content.bullets.map((item) => `<li>${item}</li>`).join("")}</ul>
    `;
  };

  const scheduleProcess = () => {
    if (reducedMotion || processSteps.length < 2) return;
    clearInterval(processTimer);
    processTimer = window.setInterval(() => {
      activeProcess = (activeProcess + 1) % processSteps.length;
      activateProcessStep(activeProcess);
    }, 4200);
  };

  processSteps.forEach((step, index) => {
    step.setAttribute("aria-pressed", String(index === 0));
    step.addEventListener("click", () => {
      activeProcess = index;
      activateProcessStep(index);
      scheduleProcess();
    });
  });

  if ("IntersectionObserver" in window && processSteps.length) {
    const processRoot = document.querySelector("[data-process]");
    const processObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) scheduleProcess();
          else clearInterval(processTimer);
        });
      },
      { threshold: 0.35 }
    );
    if (processRoot) processObserver.observe(processRoot);
  } else {
    scheduleProcess();
  }

  if (!reducedMotion && window.matchMedia("(pointer: fine)").matches) {
    document.querySelectorAll("[data-tilt]").forEach((stage) => {
      const card = stage.querySelector(".project-preview");
      if (!card) return;

      stage.addEventListener("pointermove", (event) => {
        const bounds = stage.getBoundingClientRect();
        const x = (event.clientX - bounds.left) / bounds.width - 0.5;
        const y = (event.clientY - bounds.top) / bounds.height - 0.5;
        card.style.transform = `rotateY(${x * 7 - 4}deg) rotateX(${-y * 6 + 2}deg) translate3d(${x * 4}px, ${y * 4}px, 0)`;
      });

      stage.addEventListener("pointerleave", () => {
        card.style.transform = "";
      });
    });
  }

  const initPageLoader = () => {
    const loader = document.querySelector("[data-page-loader]");
    const sitePage = document.querySelector("[data-site-page]");
    if (!loader) return;

    const minDisplay = reducedMotion ? 0 : 700;
    const started = performance.now();
    let finished = false;

    const finishLoading = () => {
      if (finished) return;
      finished = true;

      const wait = Math.max(0, minDisplay - (performance.now() - started));

      window.setTimeout(() => {
        document.body.classList.remove("is-loading");
        document.body.classList.add("is-ready");
        sitePage?.setAttribute("aria-hidden", "false");
        loader.classList.add("is-hidden");
        loader.setAttribute("aria-hidden", "true");
        initRevealAnimations();

        loader.addEventListener(
          "transitionend",
          () => {
            loader.remove();
          },
          { once: true }
        );
      }, wait);
    };

    const onWindowLoad = () => {
      waitForPageAssets().then(finishLoading);
    };

    if (document.readyState === "complete") {
      onWindowLoad();
    } else {
      window.addEventListener("load", onWindowLoad, { once: true });
    }
  };

  const year = document.querySelector("[data-year]");
  if (year) year.textContent = String(new Date().getFullYear());

  initPageLoader();
  initPreferences();
  initAppLinkNavigation();
  activateProcessStep(0);
})();
