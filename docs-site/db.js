// ── UML Sprint Tabs ──
document.querySelectorAll('.uml-tab').forEach(tab => {
  tab.addEventListener('click', () => {
    const sprint = tab.dataset.sprint;
    document.querySelectorAll('.uml-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.uml-panel').forEach(p => p.classList.remove('active'));
    tab.classList.add('active');
    document.getElementById(`uml-${sprint}`).classList.add('active');
    setTimeout(() => drawSprint(parseInt(sprint)), 80);
  });
});

// ── Pan & Zoom per panel ──
function initViewport(viewport, canvas) {
  let scale = 0.7, tx = 10, ty = 10;
  let dragging = false, sx, sy, stx, sty;

  function apply() {
    canvas.style.transform = `translate(${tx}px,${ty}px) scale(${scale})`;
  }
  apply();

  viewport.addEventListener('wheel', e => {
    e.preventDefault();
    scale = Math.max(0.3, Math.min(2, scale + (e.deltaY > 0 ? -0.07 : 0.07)));
    apply();
  }, { passive: false });

  viewport.addEventListener('mousedown', e => {
    dragging = true; sx = e.clientX; sy = e.clientY; stx = tx; sty = ty;
  });
  window.addEventListener('mousemove', e => {
    if (!dragging) return;
    tx = stx + (e.clientX - sx); ty = sty + (e.clientY - sy); apply();
  });
  window.addEventListener('mouseup', () => { dragging = false; });

  viewport.addEventListener('touchstart', e => {
    if (e.touches.length !== 1) return;
    dragging = true; sx = e.touches[0].clientX; sy = e.touches[0].clientY; stx = tx; sty = ty;
  });
  viewport.addEventListener('touchmove', e => {
    if (!dragging || e.touches.length !== 1) return;
    e.preventDefault();
    tx = stx + (e.touches[0].clientX - sx); ty = sty + (e.touches[0].clientY - sy); apply();
  }, { passive: false });
  viewport.addEventListener('touchend', () => { dragging = false; });

  // Zoom buttons: look inside parent panel OR by id suffix
  const panel = canvas.closest('.uml-panel') || canvas.closest('.er-viewport')?.parentElement;
  const zoomIn  = panel?.querySelector('.uml-zoom-in')  || document.getElementById('full-zoom-in');
  const zoomOut = panel?.querySelector('.uml-zoom-out') || document.getElementById('full-zoom-out');
  const reset   = panel?.querySelector('.uml-reset')    || document.getElementById('full-reset');
  zoomIn?.addEventListener('click',  () => { scale = Math.min(2, scale + 0.1); apply(); });
  zoomOut?.addEventListener('click', () => { scale = Math.max(0.3, scale - 0.1); apply(); });
  reset?.addEventListener('click',   () => { scale = 0.7; tx = 10; ty = 10; apply(); });
}

// Init all viewports
document.querySelectorAll('.er-viewport').forEach((vp, i) => {
  const canvas = vp.querySelector('.er-canvas');
  if (canvas) initViewport(vp, canvas);
});

// ── SVG line drawing ──
function getBox(el) {
  if (!el) return null;
  return {
    l: parseInt(el.style.left), t: parseInt(el.style.top),
    w: el.offsetWidth, h: el.offsetHeight,
  };
}

function edge(from, to) {
  const fc = { x: from.l + from.w / 2, y: from.t + from.h / 2 };
  const tc = { x: to.l + to.w / 2, y: to.t + to.h / 2 };
  const dx = tc.x - fc.x, dy = tc.y - fc.y;
  let fx, fy, tx2, ty2;
  if (Math.abs(dx) > Math.abs(dy)) {
    fx = dx > 0 ? from.l + from.w : from.l; fy = fc.y;
    tx2 = dx > 0 ? to.l : to.l + to.w; ty2 = tc.y;
  } else {
    fx = fc.x; fy = dy > 0 ? from.t + from.h : from.t;
    tx2 = tc.x; ty2 = dy > 0 ? to.t : to.t + to.h;
  }
  return { fx, fy, tx: tx2, ty: ty2 };
}

function drawLines(svgId, relations) {
  const svg = document.getElementById(svgId);
  if (!svg) return;
  svg.innerHTML = '';
  const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');

  relations.forEach(([fromId, toId, color], i) => {
    const fromEl = document.getElementById(fromId);
    const toEl   = document.getElementById(toId);
    if (!fromEl || !toEl) return;

    const mid = `arrow-${svgId}-${i}`;
    const marker = document.createElementNS('http://www.w3.org/2000/svg', 'marker');
    marker.setAttribute('id', mid);
    marker.setAttribute('markerWidth', '6'); marker.setAttribute('markerHeight', '6');
    marker.setAttribute('refX', '5'); marker.setAttribute('refY', '3');
    marker.setAttribute('orient', 'auto');
    const poly = document.createElementNS('http://www.w3.org/2000/svg', 'polygon');
    poly.setAttribute('points', '0 0, 6 3, 0 6'); poly.setAttribute('fill', color);
    marker.appendChild(poly); defs.appendChild(marker);

    const from = getBox(fromEl), to = getBox(toEl);
    if (!from || !to) return;
    const { fx, fy, tx: tx2, ty: ty2 } = edge(from, to);
    const cp1x = fx + (tx2 - fx) * 0.5, cp1y = fy;
    const cp2x = cp1x, cp2y = ty2;

    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', `M ${fx} ${fy} C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${tx2} ${ty2}`);
    path.setAttribute('fill', 'none'); path.setAttribute('stroke', color);
    path.setAttribute('stroke-width', '1.5'); path.setAttribute('stroke-opacity', '0.6');
    path.setAttribute('marker-end', `url(#${mid})`);
    svg.appendChild(path);
  });
  svg.insertBefore(defs, svg.firstChild);
}

// Relations per sprint
const SPRINT_RELATIONS = {
  1: [
    ['s1-reportes', 's1-usuarios', '#60A5FA'],
    ['s1-reportes', 's1-zonas',    '#34D399'],
  ],
  2: [
    ['s2-reportes',  's2-usuarios',       '#60A5FA'],
    ['s2-reportes',  's2-zonas',          '#34D399'],
    ['s2-reportes',  's2-corregimientos', '#34D399'],
    ['s2-reportes',  's2-veredas',        '#34D399'],
    ['s2-veredas',   's2-corregimientos', '#34D399'],
    ['s2-alertas',   's2-usuarios',       '#FBBF24'],
    ['s2-alertas',   's2-reportes',       '#FBBF24'],
    ['s2-config',    's2-usuarios',       '#FBBF24'],
    ['s2-pwreset',   's2-usuarios',       '#F87171'],
  ],
  3: [
    ['s3-reportes',   's3-usuarios',       '#60A5FA'],
    ['s3-reportes',   's3-zonas',          '#34D399'],
    ['s3-reportes',   's3-corregimientos', '#34D399'],
    ['s3-reportes',   's3-veredas',        '#34D399'],
    ['s3-reportes',   's3-incidentes',     '#FB923C'],
    ['s3-incidentes', 's3-reportes',       '#FB923C'],
    ['s3-incidentes', 's3-zonas',          '#34D399'],
    ['s3-incidentes', 's3-corregimientos', '#34D399'],
    ['s3-incidentes', 's3-veredas',        '#34D399'],
    ['s3-veredas',    's3-corregimientos', '#34D399'],
    ['s3-alertas',    's3-usuarios',       '#FBBF24'],
    ['s3-alertas',    's3-reportes',       '#FBBF24'],
    ['s3-config',     's3-usuarios',       '#FBBF24'],
    ['s3-pwreset',    's3-usuarios',       '#F87171'],
  ],
  4: [
    ['s4-reportes',    's4-usuarios',      '#60A5FA'],
    ['s4-incidentes',  's4-reportes',      '#FB923C'],
    ['s4-audit-rep',   's4-usuarios',      '#94A3B8'],
    ['s4-audit-rep',   's4-reportes',      '#94A3B8'],
    ['s4-audit-edit',  's4-usuarios',      '#94A3B8'],
    ['s4-audit-edit',  's4-reportes',      '#94A3B8'],
    ['s4-audit-usr',   's4-usuarios',      '#94A3B8'],
    ['s4-solicitudes', 's4-reportes',      '#FB923C'],
    ['s4-solicitudes', 's4-usuarios',      '#60A5FA'],
    ['s4-terminos',    's4-usuarios',      '#2DD4BF'],
  ],
};

function drawSprint(n) {
  drawLines(`svg-${n}`, SPRINT_RELATIONS[n] || []);
}

// Draw sprint 1 on load (it's the active tab)
window.addEventListener('load', () => {
  setTimeout(() => drawSprint(1), 120);
  setTimeout(() => drawFullDiagram(), 150);
});

// ── Full diagram ──
const FULL_RELATIONS = [
  ['t-reportes',      't-usuarios',        '#60A5FA'],
  ['t-reportes',      't-zonas',           '#34D399'],
  ['t-reportes',      't-corregimientos',  '#34D399'],
  ['t-reportes',      't-veredas',         '#34D399'],
  ['t-reportes',      't-incidentes',      '#FB923C'],
  ['t-incidentes',    't-reportes',        '#FB923C'],
  ['t-incidentes',    't-zonas',           '#34D399'],
  ['t-incidentes',    't-corregimientos',  '#34D399'],
  ['t-incidentes',    't-veredas',         '#34D399'],
  ['t-veredas',       't-corregimientos',  '#34D399'],
  ['t-alertas',       't-usuarios',        '#FBBF24'],
  ['t-alertas',       't-reportes',        '#FBBF24'],
  ['t-config-alertas','t-usuarios',        '#FBBF24'],
  ['t-pw-resets',     't-usuarios',        '#F87171'],
  ['t-audit-rep',     't-usuarios',        '#94A3B8'],
  ['t-audit-rep',     't-reportes',        '#94A3B8'],
  ['t-audit-edit',    't-usuarios',        '#94A3B8'],
  ['t-audit-edit',    't-reportes',        '#94A3B8'],
  ['t-audit-usr',     't-usuarios',        '#94A3B8'],
  ['t-solicitudes',   't-reportes',        '#FB923C'],
  ['t-solicitudes',   't-usuarios',        '#60A5FA'],
  ['t-terminos',      't-usuarios',        '#2DD4BF'],
];

function drawFullDiagram() {
  drawLines('svg-full', FULL_RELATIONS);
}

// Full diagram zoom buttons are handled by initViewport via full-viewport
