(() => {
  "use strict";

  const root = document.documentElement;
  const dictionary = window.IBUILD_I18N || {};
  const languageButtons = [...document.querySelectorAll("[data-lang]")];
  const fields = [...document.querySelectorAll("[data-copy], [data-alt], [data-label]")].map((el) => {
    const attribute = el.hasAttribute("data-copy") ? null : el.hasAttribute("data-alt") ? "alt" : "aria-label";
    const key = el.dataset.copy || el.dataset.alt || el.dataset.label;
    return { el, key, attribute, ru: attribute ? el.getAttribute(attribute) : el.textContent };
  });
  const russianTitle = document.title;

  function setLanguage(lang) {
    const copy = dictionary[lang] || {};
    root.lang = lang;
    document.title = copy.title || russianTitle;
    for (const { el, key, attribute, ru } of fields) {
      if (attribute) el.setAttribute(attribute, copy[key] || ru);
      else el.textContent = copy[key] || ru;
    }
    for (const button of languageButtons) button.setAttribute("aria-pressed", String(button.dataset.lang === lang));
    try { localStorage.setItem("ibuild-lang", lang); } catch {}
  }

  let initial = "ru";
  try { initial = localStorage.getItem("ibuild-lang") || initial; } catch {}
  setLanguage(["ru", "en", "uz"].includes(initial) ? initial : "ru");
  for (const button of languageButtons) button.addEventListener("click", () => setLanguage(button.dataset.lang));

  // Keep the app destination configurable when marketing and app are hosted apart.
  if (window.IBUILD_APP_URL) {
    const base = window.IBUILD_APP_URL.replace(/\/?$/, "/");
    for (const link of document.querySelectorAll("[data-app]")) link.href = base + "#/" + link.dataset.app;
  }

  const stepList = document.querySelector("[data-steps]");
  const tabs = [...stepList.querySelectorAll(".step")];
  const panels = tabs.map((tab) => document.querySelector(tab.hash));
  stepList.setAttribute("role", "tablist");
  tabs.forEach((tab, i) => {
    tab.setAttribute("role", "tab");
    tab.setAttribute("aria-controls", panels[i].id);
    panels[i].setAttribute("role", "tabpanel");
    panels[i].setAttribute("aria-labelledby", tab.id);
  });

  function select(index, moveFocus = false) {
    tabs.forEach((tab, i) => {
      tab.setAttribute("aria-selected", String(i === index));
      tab.tabIndex = i === index ? 0 : -1;
      panels[i].hidden = i !== index;
    });
    if (moveFocus) tabs[index].focus();
  }

  tabs.forEach((tab, i) => {
    tab.addEventListener("click", (event) => {
      event.preventDefault();
      select(i);
    });
    tab.addEventListener("keydown", (event) => {
      let next;
      switch (event.key) {
        case "ArrowRight":
        case "ArrowDown": next = (i + 1) % tabs.length; break;
        case "ArrowLeft":
        case "ArrowUp": next = (i + tabs.length - 1) % tabs.length; break;
        case "Home": next = 0; break;
        case "End": next = tabs.length - 1; break;
        case " ": event.preventDefault(); select(i); return;
        default: return;
      }
      event.preventDefault();
      select(next, true);
    });
  });
  function selectFromHash() {
    const index = tabs.findIndex((tab) => tab.hash === location.hash);
    if (index !== -1) select(index);
  }
  select(0);
  selectFromHash();
  window.addEventListener("hashchange", selectFromHash);

  const viewer = document.querySelector("[data-viewer]");
  const full = viewer.querySelector("[data-full]");
  let opener;
  if (typeof viewer.showModal === "function") {
    for (const link of document.querySelectorAll("[data-zoom]")) {
      link.addEventListener("click", (event) => {
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
        event.preventDefault();
        opener = link;
        full.src = link.href;
        full.alt = link.querySelector("img").alt;
        viewer.showModal();
        viewer.querySelector(".viewer-scroll").scrollTo(0, 0);
      });
    }
    viewer.addEventListener("click", (event) => {
      if (event.target === viewer) viewer.close();
    });
    viewer.addEventListener("close", () => opener?.focus());
  }
})();
