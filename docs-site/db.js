// ── ER Diagram: pan, zoom, and SVG lines ──

const viewport = document.getElementById('er-viewport');
const canvas   = document.getElementById('er-canvas');
const svg      = document.getElementById('er-svg');

let scale = 0.72, tx = 20, ty = 20;
let isDragging = false, startX, startY, startTx, startTy;

function applyTransform() {
  canvas.style.transform = `translate(${tx}px, ${ty}px) scale(${scale})`;
}
applyTransform();

// Zoom buttons
document.getElementById('btn-zoom-in').addEventListener('click', () => {
  scale = Math.min(scale + 0.1, 2);
  applyTransform();
});
document.getElementById('btn-zoom-out').addEventListener('click', () => {
  scale = Math.max(scale - 0.1, 0.3);
  applyTransform();
});
document.getElementById('btn-reset').addEventListener('click', () => {
  scale = 0.72; tx = 20; ty = 20;
  applyTransform();
});

// Scroll zoom
viewport.addEventListener('wheel', e => {
  e.preventDefault();
  const delta = e.deltaY > 0 ? -0.07 : 0.07;
  scale = Math.max(0.3, Math.min(2, scale + delta));
  applyTransform();
}, { passive: false });

// Pan
viewport.addEventListener('mousedown', e => {
  isDragging = true;
  startX = e.clientX; startY = e.clientY;
  startTx = tx; startTy = ty;
});
window.addEventListener('mousemove', e => {
  if (!isDragging) return;
  tx = startTx + (e.clientX - startX);
  ty = startTy + (e.clientY - startY);
  applyTransform();
});
window.addEventListener('mouseup', () => { isDragging = false; });

// Touch pan
viewport.addEventListener('touchstart', e => {
  if (e.touches.length === 1) {
    isDragging = true;
    startX = e.touches[0].clientX; startY = e.touches[0].clientY;
    startTx = tx; startTy = ty;
  }
});
viewport.addEventListener('touchmove', e => {
  if (!isDragging || e.touches.length !== 1) return;
  e.preventDefault();
  tx = startTx + (e.touches[0].clientX - startX);
  ty = startTy + (e.touches[0].clientY - startY);
  applyTransform();
}, { passive: false });
viewport.addEventListener('touchend', () => { isDragging = false; });

// ── SVG Relationships ──
// Each relation: [fromTableId, toTableId, color]
const RELATIONS = [
  // reportes -> usuarios
  ['t-reportes', 't-usuarios', '#60A5FA'],
  // reportes -> zonas
  ['t-reportes', 't-zonas', '#34D399'],
  // reportes -> corregimientos
  ['t-reportes', 't-corregimientos', '#34D399'],
  // reportes -> veredas
  ['t-reportes', 't-veredas', '#34D399'],
  // reportes -> incidentes
  ['t-reportes', 't-incidentes', '#FB923C'],
  // incidentes -> reportes (reporte_principal)
  ['t-incidentes', 't-reportes', '#FB923C'],
  // incidentes -> zonas
  ['t-incidentes', 't-zonas', '#34D399'],
  // incidentes -> corregimientos
  ['t-incidentes', 't-corregimientos', '#34D399'],
  // incidentes -> veredas
  ['t-incidentes', 't-veredas', '#34D399'],
  // veredas -> corregimientos
  ['t-veredas', 't-corregimientos', '#34D399'],
  // alertas -> usuarios
  ['t-alertas', 't-usuarios', '#FBBF24'],
  // alertas -> reportes
  ['t-alertas', 't-reportes', '#FBBF24'],
  // configuracion_alertas -> usuarios
  ['t-config-alertas', 't-usuarios', '#FBBF24'],
  // password_resets -> usuarios
  ['t-pw-resets', 't-usuarios', '#F87171'],
  // auditoria_reportes -> usuarios (admin_id)
  ['t-audit-rep', 't-usuarios', '#94A3B8'],
  // auditoria_reportes -> reportes
  ['t-audit-rep', 't-reportes', '#94A3B8'],
  // auditoria_edicion_reportes -> usuarios
  ['t-audit-edit', 't-usuarios', '#94A3B8'],
  // auditoria_edicion_reportes -> reportes
  ['t-audit-edit', 't-reportes', '#94A3B8'],
  // auditoria_usuarios -> usuarios (admin)
  ['t-audit-usr', 't-usuarios', '#94A3B8'],
  // solicitudes_eliminacion -> reportes
  ['t-solicitudes', 't-reportes', '#FB923C'],
  // solicitudes_eliminacion -> usuarios
  ['t-solicitudes', 't-usuarios', '#60A5FA'],
  // aceptacion_terminos -> usuarios
  ['t-terminos', 't-usuarios', '#2DD4BF'],
];

function getCenter(el) {
  const l = parseInt(el.style.left);
  const t = parseInt(el.style.top);
  return {
    x: l + el.offsetWidth / 2,
    y: t + el.offsetHeight / 2,
    left: l,
    top: t,
    right: l + el.offsetWidth,
    bottom: t + el.offsetHeight,
    w: el.offsetWidth,
    h: el.offsetHeight,
  };
}

function getEdgePoint(from, to) {
  // Pick the edge of the 'from' table that's closest to 'to'
  const fc = { x: from.left + from.w / 2, y: from.top + from.h / 2 };
  const tc = { x: to.left + to.w / 2, y: to.top + to.h / 2 };
  const dx = tc.x - fc.x;
  const dy = tc.y - fc.y;

  let fx, fy, tx2, ty2;

  if (Math.abs(dx) > Math.abs(dy)) {
    fx = dx > 0 ? from.right : from.left;
    fy = fc.y;
    tx2 = dx > 0 ? to.left : to.right;
    ty2 = tc.y;
  } else {
    fx = fc.x;
    fy = dy > 0 ? from.bottom : from.top;
    tx2 = tc.x;
    ty2 = dy > 0 ? to.top : to.bottom;
  }
  return { fx, fy, tx: tx2, ty: ty2 };
}

function drawRelations() {
  svg.innerHTML = '';
  const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');

  RELATIONS.forEach(([fromId, toId, color], i) => {
    const fromEl = document.getElementById(fromId);
    const toEl   = document.getElementById(toId);
    if (!fromEl || !toEl) return;

    const markerId = `arrow-${i}`;
    const marker = document.createElementNS('http://www.w3.org/2000/svg', 'marker');
    marker.setAttribute('id', markerId);
    marker.setAttribute('markerWidth', '6');
    marker.setAttribute('markerHeight', '6');
    marker.setAttribute('refX', '5');
    marker.setAttribute('refY', '3');
    marker.setAttribute('orient', 'auto');
    const poly = document.createElementNS('http://www.w3.org/2000/svg', 'polygon');
    poly.setAttribute('points', '0 0, 6 3, 0 6');
    poly.setAttribute('fill', color);
    marker.appendChild(poly);
    defs.appendChild(marker);

    const { fx, fy, tx: tx2, ty: ty2 } = getEdgePoint(
      { left: parseInt(fromEl.style.left), top: parseInt(fromEl.style.top), w: fromEl.offsetWidth, h: fromEl.offsetHeight },
      { left: parseInt(toEl.style.left),   top: parseInt(toEl.style.top),   w: toEl.offsetWidth,   h: toEl.offsetHeight }
    );

    const cp1x = fx + (tx2 - fx) * 0.5;
    const cp1y = fy;
    const cp2x = fx + (tx2 - fx) * 0.5;
    const cp2y = ty2;

    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', `M ${fx} ${fy} C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${tx2} ${ty2}`);
    path.setAttribute('fill', 'none');
    path.setAttribute('stroke', color);
    path.setAttribute('stroke-width', '1.5');
    path.setAttribute('stroke-opacity', '0.55');
    path.setAttribute('marker-end', `url(#${markerId})`);
    svg.appendChild(path);
  });

  svg.insertBefore(defs, svg.firstChild);
}

// Draw after layout is ready
window.addEventListener('load', () => {
  setTimeout(drawRelations, 100);
});
