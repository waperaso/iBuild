// Shrinks headings that overflow their column or run past their line budget.
// h1: 3 lines, h2: 2 lines, h2.s (side column): 3 lines. Runs before Chrome prints.
document.fonts.ready.then(() => {
  document.querySelectorAll('h1, h2').forEach(el => {
    const max = el.tagName === 'H1' ? 3 : (el.classList.contains('s') ? 3 : 2);
    let fs = parseFloat(getComputedStyle(el).fontSize);
    const lines = () => Math.round(el.getBoundingClientRect().height / (parseFloat(getComputedStyle(el).lineHeight) || fs * 1.05));
    let guard = 0;
    while ((el.scrollWidth > el.clientWidth + 1 || lines() > max) && fs > 36 && guard++ < 60) {
      fs -= 2; el.style.fontSize = fs + 'px';
    }
  });
  document.body.dataset.fit = 'done';
});
