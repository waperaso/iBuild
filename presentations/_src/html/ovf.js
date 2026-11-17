document.fonts.ready.then(() => {
  const out = [];
  document.querySelectorAll('.slide').forEach((s, si) => {
    const sr = s.getBoundingClientRect();
    const foot = s.querySelector('.bot').getBoundingClientRect();
    s.querySelectorAll('.body *').forEach(el => {
      const r = el.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) return;
      const txt = (el.innerText || '').trim().slice(0, 50).replace(/\s+/g, ' ');
      if (r.right > sr.right - 40 + 0.5 && !el.closest('.wm')) out.push(`S${si+1} RIGHT ${Math.round(r.right - sr.right + 40)}px <${el.tagName.toLowerCase()} ${el.className}> ${txt}`);
      if (r.bottom > foot.top + 0.5 && !el.closest('.wm')) out.push(`S${si+1} BOTTOM ${Math.round(r.bottom - foot.top)}px <${el.tagName.toLowerCase()} ${el.className}> ${txt}`);
      const cs = getComputedStyle(el);
      if ((cs.overflow === 'hidden' || cs.whiteSpace === 'nowrap') && el.scrollWidth > el.clientWidth + 1 && el.children.length === 0) out.push(`S${si+1} CLIP ${el.scrollWidth - el.clientWidth}px <${el.tagName.toLowerCase()} ${el.className}> ${txt}`);
    });
  });
  const pre = document.createElement('pre'); pre.id = 'ovf'; pre.textContent = out.join('\n') || 'OK'; document.body.appendChild(pre);
});
