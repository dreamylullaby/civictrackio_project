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

// SVG namespace helper
const SVG_NS = 'http://www.w3.org/2000/svg';
function svgEl(tag, attrs) {
  const el = document.createElementNS(SVG_NS, tag);
  Object.entries(attrs).forEach(([k, v]) => el.setAttribute(k, v));
  return el;
}

/**
 * drawLines — relation format:
 * [fromId, toId, color, label?, cardFrom?, cardTo?]
 *
 * cardFrom/cardTo: '1', '*', '0..1', '0..*', '1..*'
 * label: relationship name shown mid-line
 */
function drawLines(svgId, relations) {
  const svg = document.getElementById(svgId);
  if (!svg) return;
  svg.innerHTML = '';
  const defs = svgEl('defs', {});

  relations.forEach(([fromId, toId, color, label, cardFrom, cardTo], i) => {
    const fromEl = document.getElementById(fromId);
    const toEl   = document.getElementById(toId);
    if (!fromEl || !toEl) return;

    // ── Arrow marker (filled triangle) ──
    const mid = `arrow-${svgId}-${i}`;
    const marker = svgEl('marker', {
      id: mid, markerWidth: '8', markerHeight: '8',
      refX: '7', refY: '4', orient: 'auto',
    });
    marker.appendChild(svgEl('polygon', {
      points: '0 0, 8 4, 0 8', fill: color,
    }));
    defs.appendChild(marker);

    const from = getBox(fromEl), to = getBox(toEl);
    if (!from || !to) return;
    const { fx, fy, tx: tx2, ty: ty2 } = edge(from, to);

    // Cubic bezier control points
    const cp1x = fx + (tx2 - fx) * 0.5, cp1y = fy;
    const cp2x = cp1x, cp2y = ty2;

    // ── Main path ──
    svg.appendChild(svgEl('path', {
      d: `M ${fx} ${fy} C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${tx2} ${ty2}`,
      fill: 'none', stroke: color,
      'stroke-width': '1.8', 'stroke-opacity': '0.75',
      'marker-end': `url(#${mid})`,
    }));

    // Midpoint along the bezier (t=0.5)
    const mx = 0.125*fx + 0.375*cp1x + 0.375*cp2x + 0.125*tx2;
    const my = 0.125*fy + 0.375*cp1y + 0.375*cp2y + 0.125*ty2;

    // ── Relationship label (mid) ──
    if (label) {
      // pill background
      const rect = svgEl('rect', {
        x: mx - 34, y: my - 9,
        width: '68', height: '16',
        rx: '5', ry: '5',
        fill: '#0f172a', stroke: color,
        'stroke-width': '1', opacity: '0.92',
      });
      const txt = svgEl('text', {
        x: mx, y: my + 3,
        'text-anchor': 'middle',
        fill: color,
        'font-size': '9',
        'font-family': 'Inter, sans-serif',
        'font-weight': '600',
        'letter-spacing': '0.03em',
      });
      txt.textContent = label;
      svg.appendChild(rect);
      svg.appendChild(txt);
    }

    // ── Cardinality labels ──
    // cardFrom near source (offset along the line start)
    const OFFSET = 22;
    function cardLabel(x, y, text, anchor) {
      if (!text) return;
      const bg = svgEl('rect', {
        x: anchor === 'start' ? x - 2 : x - 18,
        y: y - 9, width: '20', height: '13',
        rx: '3', fill: '#0f172a', opacity: '0.85',
      });
      const t = svgEl('text', {
        x, y: y + 2,
        'text-anchor': 'middle',
        fill: '#e2e8f0',
        'font-size': '9.5',
        'font-family': 'Inter, sans-serif',
        'font-weight': '700',
      });
      t.textContent = text;
      svg.appendChild(bg);
      svg.appendChild(t);
    }

    if (cardFrom) {
      const dx = tx2 - fx, dy2 = ty2 - fy;
      const len = Math.sqrt(dx*dx + dy2*dy2) || 1;
      cardLabel(fx + (dx/len)*OFFSET, fy + (dy2/len)*OFFSET, cardFrom, 'start');
    }
    if (cardTo) {
      const dx = fx - tx2, dy2 = fy - ty2;
      const len = Math.sqrt(dx*dx + dy2*dy2) || 1;
      cardLabel(tx2 + (dx/len)*OFFSET, ty2 + (dy2/len)*OFFSET, cardTo, 'end');
    }
  });

  svg.insertBefore(defs, svg.firstChild);
}

// Relations per sprint
// Format: [fromId, toId, color, label, cardFrom, cardTo]
const SPRINT_RELATIONS = {
  1: [
    ['s1-reportes', 's1-usuarios', '#60A5FA', 'registra',  '*', '1'],
    ['s1-reportes', 's1-zonas',    '#34D399', 'ubicado en','*', '1'],
  ],
  2: [
    ['s2-reportes',  's2-usuarios',       '#60A5FA', 'registra',    '*',    '1'],
    ['s2-reportes',  's2-zonas',          '#34D399', 'ubicado en',  '*',    '1'],
    ['s2-reportes',  's2-corregimientos', '#34D399', 'rural en',    '*',    '0..1'],
    ['s2-reportes',  's2-veredas',        '#34D399', 'vereda',      '*',    '0..1'],
    ['s2-veredas',   's2-corregimientos', '#34D399', 'pertenece a', '*',    '1'],
    ['s2-alertas',   's2-usuarios',       '#FBBF24', 'notifica',    '*',    '1'],
    ['s2-alertas',   's2-reportes',       '#FBBF24', 'sobre',       '*',    '1'],
    ['s2-config',    's2-usuarios',       '#FBBF24', 'configura',   '1',    '1'],
    ['s2-pwreset',   's2-usuarios',       '#F87171', 'solicita',    '*',    '1'],
  ],
  3: [
    ['s3-reportes',   's3-usuarios',       '#60A5FA', 'registra',    '*',    '1'],
    ['s3-reportes',   's3-zonas',          '#34D399', 'ubicado en',  '*',    '1'],
    ['s3-reportes',   's3-corregimientos', '#34D399', 'rural en',    '*',    '0..1'],
    ['s3-reportes',   's3-veredas',        '#34D399', 'vereda',      '*',    '0..1'],
    ['s3-reportes',   's3-incidentes',     '#FB923C', 'agrupa en',   '*',    '0..1'],
    ['s3-incidentes', 's3-reportes',       '#FB923C', 'principal',   '1',    '1'],
    ['s3-incidentes', 's3-zonas',          '#34D399', 'ubicado en',  '*',    '1'],
    ['s3-incidentes', 's3-corregimientos', '#34D399', 'rural en',    '*',    '0..1'],
    ['s3-incidentes', 's3-veredas',        '#34D399', 'vereda',      '*',    '0..1'],
    ['s3-veredas',    's3-corregimientos', '#34D399', 'pertenece a', '*',    '1'],
    ['s3-alertas',    's3-usuarios',       '#FBBF24', 'notifica',    '*',    '1'],
    ['s3-alertas',    's3-reportes',       '#FBBF24', 'sobre',       '*',    '1'],
    ['s3-config',     's3-usuarios',       '#FBBF24', 'configura',   '1',    '1'],
    ['s3-pwreset',    's3-usuarios',       '#F87171', 'solicita',    '*',    '1'],
  ],
  4: [
    ['s4-reportes',    's4-usuarios',   '#60A5FA', 'registra',      '*',    '1'],
    ['s4-incidentes',  's4-reportes',   '#FB923C', 'principal',     '1',    '1'],
    ['s4-audit-rep',   's4-usuarios',   '#94A3B8', 'admin',         '*',    '1'],
    ['s4-audit-rep',   's4-reportes',   '#94A3B8', 'audita',        '*',    '1'],
    ['s4-audit-edit',  's4-usuarios',   '#94A3B8', 'editor',        '*',    '1'],
    ['s4-audit-edit',  's4-reportes',   '#94A3B8', 'edición',       '*',    '1'],
    ['s4-audit-usr',   's4-usuarios',   '#94A3B8', 'audita',        '*',    '1'],
    ['s4-solicitudes', 's4-reportes',   '#FB923C', 'sobre',         '*',    '1'],
    ['s4-solicitudes', 's4-usuarios',   '#60A5FA', 'solicitante',   '*',    '1'],
    ['s4-terminos',    's4-usuarios',   '#2DD4BF', 'acepta',        '*',    '1'],
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
// Format: [fromId, toId, color, label, cardFrom, cardTo]
const FULL_RELATIONS = [
  ['t-reportes',       't-usuarios',        '#60A5FA', 'registra',    '*',    '1'],
  ['t-reportes',       't-zonas',           '#34D399', 'ubicado en',  '*',    '1'],
  ['t-reportes',       't-corregimientos',  '#34D399', 'rural en',    '*',    '0..1'],
  ['t-reportes',       't-veredas',         '#34D399', 'vereda',      '*',    '0..1'],
  ['t-reportes',       't-incidentes',      '#FB923C', 'agrupa en',   '*',    '0..1'],
  ['t-incidentes',     't-reportes',        '#FB923C', 'principal',   '1',    '1'],
  ['t-incidentes',     't-zonas',           '#34D399', 'ubicado en',  '*',    '1'],
  ['t-incidentes',     't-corregimientos',  '#34D399', 'rural en',    '*',    '0..1'],
  ['t-incidentes',     't-veredas',         '#34D399', 'vereda',      '*',    '0..1'],
  ['t-veredas',        't-corregimientos',  '#34D399', 'pertenece a', '*',    '1'],
  ['t-alertas',        't-usuarios',        '#FBBF24', 'notifica',    '*',    '1'],
  ['t-alertas',        't-reportes',        '#FBBF24', 'sobre',       '*',    '1'],
  ['t-config-alertas', 't-usuarios',        '#FBBF24', 'configura',   '1',    '1'],
  ['t-pw-resets',      't-usuarios',        '#F87171', 'solicita',    '*',    '1'],
  ['t-audit-rep',      't-usuarios',        '#94A3B8', 'admin',       '*',    '1'],
  ['t-audit-rep',      't-reportes',        '#94A3B8', 'audita',      '*',    '1'],
  ['t-audit-edit',     't-usuarios',        '#94A3B8', 'editor',      '*',    '1'],
  ['t-audit-edit',     't-reportes',        '#94A3B8', 'edición',     '*',    '1'],
  ['t-audit-usr',      't-usuarios',        '#94A3B8', 'audita usr',  '*',    '1'],
  ['t-solicitudes',    't-reportes',        '#FB923C', 'sobre',       '*',    '1'],
  ['t-solicitudes',    't-usuarios',        '#60A5FA', 'solicitante', '*',    '1'],
  ['t-terminos',       't-usuarios',        '#2DD4BF', 'acepta',      '*',    '1'],
];

function drawFullDiagram() {
  drawLines('svg-full', FULL_RELATIONS);
}

// Full diagram zoom buttons are handled by initViewport via full-viewport
