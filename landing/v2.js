/* iBuild landing v2 — motion engine.
   No dependencies. One rAF loop for anything scroll- or pointer-driven,
   IntersectionObserver for one-shot reveals. Everything degrades to a plain
   static page when prefers-reduced-motion is set or JS fails. */
(() => {
  'use strict';

  const q = (s, r = document) => r.querySelector(s);
  const qa = (s, r = document) => [...r.querySelectorAll(s)];
  const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v));
  const lerp = (a, b, t) => a + (b - a) * t;
  const calm = matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ─────────────── i18n ─────────────── */
  const DICT = window.IBUILD_V2_I18N || {};
  const SUPPORTED = ['ru', 'en', 'uz'];
  const resolve = lang => DICT[lang] || DICT.ru;

  function applyLang(lang) {
    const d = resolve(lang);
    if (!d) return;
    qa('[data-i18n]').forEach(el => {
      const v = d[el.dataset.i18n];
      if (v != null) el.textContent = v;
    });
    qa('[data-i18n-attr]').forEach(el => {
      const [attr, key] = el.dataset.i18nAttr.split(':');
      if (d[key] != null) el.setAttribute(attr, d[key]);
    });
    // One screenshot set per interface language, so copy and screens always match.
    const shotLang = SUPPORTED.includes(lang) ? lang : 'ru';
    qa('[data-shot]').forEach(img => {
      const next = `assets/screens/${shotLang}/${img.dataset.shot}.png`;
      if (!img.src.endsWith(next)) img.src = next;
    });
    splitHeadings();
    const ticker = q('[data-ticker]');
    if (ticker) {
      const items = ['stepRequest', 'stepInspection', 'stepReview', 'stepApproval',
        'control1', 'control2', 'control3', 'control4'].map(k => d[k]).filter(Boolean);
      // two passes, so the -50% loop joins seamlessly
      ticker.innerHTML = [...items, ...items].map(t => `<span>${t}</span>`).join('');
    }
    document.documentElement.lang = DICT[lang] ? lang : 'ru';
    qa('.langs button').forEach(b => b.setAttribute('aria-pressed', String(b.dataset.lang === lang)));
    try { localStorage.setItem('ibuild-lang', lang); } catch (e) { /* private mode */ }
  }

  // Headings animate word by word; i18n rewrites textContent, so re-split after it.
  function splitHeadings() {
    qa('h2.kin').forEach(h => {
      const text = h.textContent.trim();
      if (h.dataset.split === text) return;
      h.dataset.split = text;
      h.innerHTML = text.split(/\s+/)
        .map(w => `<span class="kw"><span>${w}</span></span>`).join(' ');
      if (h.classList.contains('is-in')) h.classList.add('kin-done');
    });
  }

  let stored = null;
  try { stored = localStorage.getItem('ibuild-lang'); } catch (e) { /* ignore */ }
  const initial = SUPPORTED.includes(stored) ? stored
    : SUPPORTED.find(l => navigator.language && navigator.language.toLowerCase().startsWith(l)) || 'ru';
  applyLang(initial);
  qa('.langs button').forEach(b => b.addEventListener('click', () => applyLang(b.dataset.lang)));

  /* ─────────────── app links ─────────────── */
  // Same contract as the v1 landing: when marketing and the app live on
  // different hosts, set window.IBUILD_APP_URL before this script loads.
  if (window.IBUILD_APP_URL) {
    const base = String(window.IBUILD_APP_URL).replace(/\/?$/, '/');
    qa('[data-app]').forEach(a => { a.href = base + '#/' + a.dataset.app; });
  }

  /* ─────────────── reveal on enter ─────────────── */
  // h2.kin hides its own words until it gets .is-in, so every kinetic heading must be
  // observed even if someone forgets the .reveal class on it.
  const reveals = [...new Set([...qa('.reveal'), ...qa('h2.kin')])];
  reveals.forEach(el => { if (el.dataset.d) el.style.setProperty('--d', el.dataset.d); });

  if (calm) {
    reveals.forEach(el => el.classList.add('is-in'));
    qa('.num').forEach(el => el.classList.add('is-in'));
  } else {
    const io = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (!e.isIntersecting) return;
        e.target.classList.add('is-in');
        io.unobserve(e.target);
      });
    }, { rootMargin: '0px 0px -12% 0px', threshold: 0.12 });
    reveals.forEach(el => io.observe(el));
  }

  /* ─────────────── counters ─────────────── */
  const fmt = v => v.toFixed(1).replace('.', ',').replace(/\B(?=(\d{3})+(?!,))/g, ' ');
  const counters = qa('[data-count]');
  if (calm) {
    counters.forEach(el => { el.textContent = fmt(parseFloat(el.dataset.count)); });
  } else {
    const cio = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (!e.isIntersecting) return;
        const el = e.target;
        cio.unobserve(el);
        el.closest('.num')?.classList.add('is-in');
        const target = parseFloat(el.dataset.count);
        const dur = 1500;
        const t0 = performance.now();
        const tick = now => {
          const p = clamp((now - t0) / dur);
          const eased = 1 - Math.pow(1 - p, 4);
          el.textContent = fmt(target * eased);
          if (p < 1) requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);
      });
    }, { threshold: 0.5 });
    counters.forEach(el => cio.observe(el));
  }

  /* ─────────────── sticky walkthrough ─────────────── */
  // Regions are percentages of the 1920×1140 screenshots.
  const STEPS = [
    { name: 'frameDeveloper', ring: [28.0, 47.8, 44.0, 5.9], cur: [50.0, 87.7] },
    { name: 'frameBank', ring: [26.0, 45.2, 71.6, 11.7], cur: [60.0, 51.0] },
    { name: 'frameBank', ring: [69.5, 41.1, 13.4, 14.2], cur: [69.0, 70.5] },
    { name: 'frameBank', ring: [26.0, 60.5, 42.2, 9.2], cur: [74.0, 93.0] },
  ];

  const walk = q('[data-walk] .walk');
  const slides = qa('[data-walk-slide]');
  const wsteps = qa('.wstep');
  const ring = q('[data-walk-ring]');
  const cursor = q('[data-walk-cursor]');
  const wname = q('[data-walk-name]');
  const wcount = q('[data-walk-count]');
  const wprog = q('[data-walk-prog]');
  let lastStep = -1;

  function setStep(i, local) {
    if (i !== lastStep) {
      lastStep = i;
      slides.forEach((s, k) => s.classList.toggle('is-on', k === i));
      wsteps.forEach((s, k) => s.classList.toggle('is-on', k === i));
      const s = STEPS[i];
      if (wname) wname.textContent = (resolve(document.documentElement.lang) || {})[s.name] || '';
      if (wcount) wcount.textContent = `0${i + 1} / 04`;
      if (ring) {
        ring.style.setProperty('--x', s.ring[0] + '%');
        ring.style.setProperty('--y', s.ring[1] + '%');
        ring.style.setProperty('--w', s.ring[2] + '%');
        ring.style.setProperty('--h', s.ring[3] + '%');
      }
      if (cursor) {
        cursor.style.setProperty('--cx', s.cur[0] + '%');
        cursor.style.setProperty('--cy', s.cur[1] + '%');
      }
    }
    // the ring and cursor arrive a beat after the screen does
    ring?.classList.toggle('is-on', local > 0.18);
    cursor?.classList.toggle('is-on', local > 0.3);
  }

  function updateWalk() {
    if (!walk) return;
    const r = walk.getBoundingClientRect();
    const span = walk.offsetHeight - window.innerHeight;
    if (span <= 0) return;
    const p = clamp(-r.top / span);
    const raw = p * STEPS.length;
    const i = Math.min(STEPS.length - 1, Math.floor(raw));
    setStep(i, raw - i);
    if (wprog) wprog.style.height = (p * 100).toFixed(2) + '%';
  }

  /* ─────────────── parallax + tilt ─────────────── */
  const parallax = qa('[data-par]');
  const tilts = qa('[data-tilt]');
  const nav = q('.nav');
  const heroStage = q('.hero-stage');
  const progress = q('[data-progress]');
  const glow = q('[data-glow]');
  const control = q('.control');
  const pointer = { x: 0, y: 0 };
  const smooth = { x: 0, y: 0 };
  let hasPointer = false;

  if (!calm && matchMedia('(hover: hover)').matches) {
    addEventListener('pointermove', e => {
      pointer.x = (e.clientX / innerWidth) * 2 - 1;
      pointer.y = (e.clientY / innerHeight) * 2 - 1;
      hasPointer = true;
    }, { passive: true });
  }

  function frame() {
    const y = scrollY;
    nav?.classList.toggle('is-stuck', y > 20);

    if (progress) {
      const max = document.documentElement.scrollHeight - innerHeight;
      progress.style.width = (max > 0 ? clamp(y / max) * 100 : 0).toFixed(2) + '%';
    }

    if (!calm) {
      const t = performance.now() / 1000;

      // chips and orbs drift on scroll, and keep breathing when it stops
      for (const el of parallax) {
        const f = parseFloat(el.dataset.par);
        const bob = el.classList.contains('chip') ? Math.sin(t * 0.9 + f * 24) * 6 : 0;
        el.style.transform = `translate3d(0, ${(y * f + bob).toFixed(2)}px, 0)`;
      }

      // the hero panel lifts away rather than just scrolling off
      if (heroStage) {
        const hp = clamp(y / (innerHeight * 0.9));
        heroStage.style.opacity = (1 - hp * 0.75).toFixed(3);
        heroStage.style.transform = `translate3d(0, ${(hp * -40).toFixed(1)}px, 0) scale(${(1 - hp * 0.06).toFixed(4)})`;
      }

      smooth.x = lerp(smooth.x, pointer.x, 0.07);
      smooth.y = lerp(smooth.y, pointer.y, 0.07);

      for (const el of tilts) {
        const soft = el.hasAttribute('data-tilt-soft') ? 0.45 : 1;
        const r = el.getBoundingClientRect();
        // flatten the hero panel as it scrolls away
        const prog = clamp(1 - (r.top + r.height * 0.3) / innerHeight);
        const baseY = lerp(-9, 0, prog) * soft;
        const baseX = lerp(5.5, 0, prog) * soft;
        const mx = hasPointer ? smooth.x * 4 * soft : 0;
        const my = hasPointer ? smooth.y * -3 * soft : 0;
        // a slow bob keeps the panel alive when the page is still
        const bob = el.hasAttribute('data-tilt-soft') ? 0 : Math.sin(t * 0.55) * 5;
        el.style.transform =
          `perspective(1400px) translate3d(0, ${bob.toFixed(2)}px, 0) ` +
          `rotateX(${(baseX + my).toFixed(2)}deg) rotateY(${(baseY + mx).toFixed(2)}deg)`;
      }
    }

    updateWalk();
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);

  /* ─────────────── card tilt ─────────────── */
  if (!calm && matchMedia('(hover: hover)').matches) {
    qa('.card').forEach(card => {
      card.addEventListener('pointermove', e => {
        const r = card.getBoundingClientRect();
        const dx = (e.clientX - (r.left + r.width / 2)) / r.width;
        const dy = (e.clientY - (r.top + r.height / 2)) / r.height;
        card.style.transform =
          `perspective(900px) rotateX(${(-dy * 5).toFixed(2)}deg) rotateY(${(dx * 6).toFixed(2)}deg) translateY(-5px)`;
      });
      card.addEventListener('pointerleave', () => { card.style.transform = ''; });
    });

    // the dark section lights up under the cursor
    if (control && glow) {
      control.addEventListener('pointermove', e => {
        const r = control.getBoundingClientRect();
        glow.style.setProperty('--gx', (e.clientX - r.left) + 'px');
        glow.style.setProperty('--gy', (e.clientY - r.top) + 'px');
      }, { passive: true });
    }
  }

  /* ─────────────── magnetic buttons ─────────────── */
  if (!calm && matchMedia('(hover: hover)').matches) {
    qa('.btn-lg, .btn-solid').forEach(btn => {
      btn.addEventListener('pointermove', e => {
        const r = btn.getBoundingClientRect();
        const dx = (e.clientX - (r.left + r.width / 2)) / r.width;
        const dy = (e.clientY - (r.top + r.height / 2)) / r.height;
        btn.style.transform = `translate(${(dx * 8).toFixed(1)}px, ${(dy * 6 - 2).toFixed(1)}px)`;
      });
      btn.addEventListener('pointerleave', () => { btn.style.transform = ''; });
    });
  }

  /* ─────────────── nav: current section ─────────────── */
  const sections = ['#process', '#control', '#roles']
    .map(h => ({ h, el: q(h) })).filter(s => s.el);
  const links = new Map(qa('.nav-links a').map(a => [a.getAttribute('href'), a]));
  if (sections.length) {
    const sio = new IntersectionObserver(entries => {
      entries.forEach(e => {
        const link = links.get('#' + e.target.id);
        if (link) link.style.color = e.isIntersecting ? 'var(--blue)' : '';
      });
    }, { rootMargin: '-45% 0px -50% 0px' });
    sections.forEach(s => sio.observe(s.el));
  }
})();
