// Macro side-by-side panel hover highlighting.
// Elements with matching data-group attributes highlight together on hover.

document.querySelectorAll('.macro-panel [data-group]').forEach(el => {
  el.addEventListener('mouseenter', () => {
    const group = el.dataset.group;
    document.querySelectorAll(`.macro-panel [data-group="${group}"]`).forEach(match => {
      match.classList.add('highlight');
    });
  });

  el.addEventListener('mouseleave', () => {
    const group = el.dataset.group;
    document.querySelectorAll(`.macro-panel [data-group="${group}"]`).forEach(match => {
      match.classList.remove('highlight');
    });
  });
});
