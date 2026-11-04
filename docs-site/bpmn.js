// ── BPMN Lightbox ──
const cards = Array.from(document.querySelectorAll('.bpmn-card'));
const lightbox = document.getElementById('lightbox');
const lbImg    = document.getElementById('lb-img');
const lbTitle  = document.getElementById('lb-title');
const lbCounter = document.getElementById('lb-counter');
const lbClose  = document.getElementById('lb-close');
const lbBackdrop = document.getElementById('lb-backdrop');
const lbPrev   = document.getElementById('lb-prev');
const lbNext   = document.getElementById('lb-next');

let current = 0;

function openLightbox(index) {
  current = index;
  updateLightbox();
  lightbox.classList.add('open');
  document.body.style.overflow = 'hidden';
}

function closeLightbox() {
  lightbox.classList.remove('open');
  document.body.style.overflow = '';
}

function updateLightbox() {
  const card = cards[current];
  lbImg.src = card.dataset.img;
  lbImg.alt = card.dataset.title;
  lbTitle.textContent = card.dataset.title;
  lbCounter.textContent = `${current + 1} / ${cards.length}`;
}

function prev() { current = (current - 1 + cards.length) % cards.length; updateLightbox(); }
function next() { current = (current + 1) % cards.length; updateLightbox(); }

cards.forEach((card, i) => card.addEventListener('click', () => openLightbox(i)));
lbClose.addEventListener('click', closeLightbox);
lbBackdrop.addEventListener('click', closeLightbox);
lbPrev.addEventListener('click', prev);
lbNext.addEventListener('click', next);

document.addEventListener('keydown', e => {
  if (!lightbox.classList.contains('open')) return;
  if (e.key === 'Escape') closeLightbox();
  if (e.key === 'ArrowLeft') prev();
  if (e.key === 'ArrowRight') next();
});
