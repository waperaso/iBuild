(function () {
  "use strict";

  // Where the app lives. Same origin by default; set window.IBUILD_APP_URL before this
  // script (for example "https://app.example.uz/") when the landing is hosted apart.
  var APP = (window.IBUILD_APP_URL || "/").replace(/\/?$/, "/");
  var ROUTES = { demo: "#/login", register: "#/register", login: "#/login" };

  var root = document.documentElement;
  var dict = (window.IBUILD_I18N || {});
  var ru = {};

  function save(key, value) {
    try { localStorage.setItem(key, value); } catch (e) {}
  }

  // ---- Language: Russian is the text in the page; en/uz come from i18n.js ----
  document.querySelectorAll("[data-i18n],[data-i18n-html]").forEach(function (el) {
    var key = el.getAttribute("data-i18n") || el.getAttribute("data-i18n-html");
    ru[key] = el.innerHTML;
  });

  function setLang(lang) {
    root.setAttribute("lang", lang);
    document.querySelectorAll("[data-i18n],[data-i18n-html]").forEach(function (el) {
      var key = el.getAttribute("data-i18n") || el.getAttribute("data-i18n-html");
      var text = lang === "ru" ? ru[key] : (dict[lang] && dict[lang][key]);
      if (text == null) text = ru[key];
      if (el.hasAttribute("data-i18n-html")) el.innerHTML = text;
      else el.textContent = text;
    });
    document.querySelectorAll(".lang-btn").forEach(function (b) {
      b.setAttribute("aria-pressed", String(b.getAttribute("data-lang") === lang));
    });
    var titles = {
      ru: "iBuild — мониторинг проектного финансирования",
      en: "iBuild — project finance monitoring",
      uz: "iBuild — loyiha moliyalashtirish monitoringi"
    };
    document.title = titles[lang] || titles.ru;
    save("ibuild-lang", lang);
  }

  document.querySelectorAll(".lang-btn").forEach(function (b) {
    b.addEventListener("click", function () { setLang(b.getAttribute("data-lang")); });
  });
  var startLang = root.getAttribute("lang");
  if (startLang === "en" || startLang === "uz") setLang(startLang);

  // ---- Theme ----
  document.querySelectorAll("[data-theme-toggle]").forEach(function (b) {
    b.addEventListener("click", function () {
      var next = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
      root.setAttribute("data-theme", next);
      save("ibuild-theme", next);
    });
  });

  // ---- App links ----
  document.querySelectorAll("[data-app]").forEach(function (a) {
    a.setAttribute("href", APP + (ROUTES[a.getAttribute("data-app")] || ""));
  });

  // ---- Header ----
  var header = document.querySelector("[data-header]");
  function onScroll() {
    header.classList.toggle("is-scrolled", window.scrollY > 24);
  }
  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });

  // ---- Mobile menu ----
  var menu = document.querySelector("[data-mobile-menu]");
  var toggle = document.querySelector("[data-menu-toggle]");
  function setMenu(open) {
    menu.classList.toggle("is-open", open);
    toggle.setAttribute("aria-expanded", String(open));
    document.body.style.overflow = open ? "hidden" : "";
  }
  toggle.addEventListener("click", function () { setMenu(!menu.classList.contains("is-open")); });
  document.querySelectorAll("[data-close-menu]").forEach(function (a) {
    a.addEventListener("click", function () { setMenu(false); });
  });
  window.addEventListener("keydown", function (e) { if (e.key === "Escape") setMenu(false); });

  // ---- Active nav link ----
  var links = Array.prototype.slice.call(document.querySelectorAll(".desktop-nav a"));
  var targets = links.map(function (a) { return document.querySelector(a.getAttribute("href")); });
  if ("IntersectionObserver" in window) {
    var spy = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        var i = targets.indexOf(entry.target);
        links.forEach(function (a, n) { a.classList.toggle("is-active", n === i); });
      });
    }, { rootMargin: "-45% 0px -50% 0px" });
    targets.forEach(function (t) { if (t) spy.observe(t); });
  }

  // ---- Reveal on scroll ----
  var reveals = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12 });
    reveals.forEach(function (el) { io.observe(el); });
  } else {
    reveals.forEach(function (el) { el.classList.add("is-visible"); });
  }

  // ---- Document preview tabs ----
  var tabs = Array.prototype.slice.call(document.querySelectorAll(".doc-tab"));
  var panes = Array.prototype.slice.call(document.querySelectorAll(".doc-pane"));
  function showDoc(key) {
    tabs.forEach(function (t) { t.setAttribute("aria-selected", String(t.getAttribute("data-doc") === key)); });
    panes.forEach(function (p) { p.classList.toggle("is-active", p.getAttribute("data-pane") === key); });
  }
  tabs.forEach(function (t, i) {
    t.addEventListener("click", function () { showDoc(t.getAttribute("data-doc")); });
    t.addEventListener("keydown", function (e) {
      if (e.key !== "ArrowDown" && e.key !== "ArrowUp") return;
      e.preventDefault();
      var next = tabs[(i + (e.key === "ArrowDown" ? 1 : tabs.length - 1)) % tabs.length];
      next.focus();
      showDoc(next.getAttribute("data-doc"));
    });
  });

  // ---- Footer year ----
  document.querySelectorAll("[data-year]").forEach(function (el) { el.textContent = new Date().getFullYear(); });
})();
