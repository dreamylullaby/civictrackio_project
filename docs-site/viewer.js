const MANUALS = {
  usuario: {
    label: 'Manual de usuario final · App móvil',
    file: 'manuales/manual-usuario.md',
    filename: 'CivicTrackIO-Manual-Usuario',
  },
  admin: {
    label: 'Manual de administrador · Dashboard web',
    file: 'manuales/manual-admin.md',
    filename: 'CivicTrackIO-Manual-Admin',
  },
  tecnico: {
    label: 'Manual técnico · Instalación y configuración',
    file: 'manuales/manual-tecnico.md',
    filename: 'CivicTrackIO-Manual-Tecnico',
  },
  despliegue: {
    label: 'Manual de despliegue · Render · Netlify · Supabase',
    file: 'manuales/manual-despliegue.md',
    filename: 'CivicTrackIO-Manual-Despliegue',
  },
};

let currentMeta = null;
let currentMd = '';

function getParam(name) {
  return new URLSearchParams(window.location.search).get(name);
}

function slugify(text) {
  return text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

function buildTOC(headings) {
  const list = document.getElementById('toc-list');
  list.innerHTML = '';
  headings.forEach(h => {
    const li = document.createElement('li');
    if (h.level === 3) li.classList.add('toc-h3');
    li.innerHTML = `<a href="#${h.id}">${h.text}</a>`;
    list.appendChild(li);
  });
}

function highlightTOC() {
  const links = document.querySelectorAll('#toc-list a');
  const headings = Array.from(document.querySelectorAll('.markdown-body h2, .markdown-body h3'));
  const scrollY = window.scrollY + 80;
  let active = headings[0];
  headings.forEach(h => { if (h.offsetTop <= scrollY) active = h; });
  links.forEach(a => {
    a.classList.toggle('toc-active', active && a.getAttribute('href') === '#' + active.id);
  });
}

// ── PDF export ──
async function exportPDF() {
  const { jsPDF } = window.jspdf;
  const content = document.getElementById('manual-content');
  const canvas = await html2canvas(content, {
    backgroundColor: '#0F172A',
    scale: 1.5,
    useCORS: true,
    logging: false,
  });
  const imgData = canvas.toDataURL('image/png');
  const pdf = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
  const pageW = pdf.internal.pageSize.getWidth();
  const pageH = pdf.internal.pageSize.getHeight();
  const imgW = pageW - 20;
  const imgH = (canvas.height * imgW) / canvas.width;
  let y = 10;
  let remaining = imgH;
  const firstH = Math.min(remaining, pageH - 20);
  pdf.addImage(imgData, 'PNG', 10, y, imgW, imgH, '', 'FAST');
  remaining -= firstH;
  let page = 1;
  while (remaining > 0) {
    pdf.addPage();
    page++;
    const offsetY = -((page - 1) * (pageH - 20)) + 10;
    pdf.addImage(imgData, 'PNG', 10, offsetY, imgW, imgH, '', 'FAST');
    remaining -= (pageH - 20);
  }
  pdf.save(`${currentMeta.filename}.pdf`);
}

// ── Word export (HTML → .doc trick) ──
function exportWord() {
  const content = document.getElementById('manual-content').innerHTML;
  const html = `
    <html xmlns:o='urn:schemas-microsoft-com:office:office'
          xmlns:w='urn:schemas-microsoft-com:office:word'
          xmlns='http://www.w3.org/TR/REC-html40'>
    <head>
      <meta charset='utf-8'>
      <title>${currentMeta.label}</title>
      <style>
        body { font-family: Calibri, sans-serif; font-size: 11pt; color: #1e293b; line-height: 1.6; margin: 2cm; }
        h1 { font-size: 20pt; color: #1e3a8a; }
        h2 { font-size: 15pt; color: #1e3a8a; border-bottom: 1px solid #cbd5e1; padding-bottom: 4pt; }
        h3 { font-size: 12pt; color: #334155; }
        table { border-collapse: collapse; width: 100%; }
        th { background: #1e3a8a; color: #fff; padding: 6pt; font-size: 10pt; text-align: left; }
        td { border: 1px solid #cbd5e1; padding: 5pt; font-size: 10pt; }
        code { font-family: Consolas, monospace; background: #f1f5f9; padding: 1pt 3pt; font-size: 10pt; }
        blockquote { border-left: 3pt solid #6d6df9; padding-left: 10pt; color: #64748b; }
        li { margin-bottom: 4pt; }
      </style>
    </head>
    <body>${content}</body>
    </html>`;
  const blob = new Blob([html], { type: 'application/msword' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${currentMeta.filename}.doc`;
  a.click();
  URL.revokeObjectURL(url);
}

// ── Hamburger nav ──
function initHamburger() {
  const btn = document.getElementById('nav-hamburger');
  const links = document.getElementById('viewer-nav-links');
  if (!btn || !links) return;
  btn.addEventListener('click', () => links.classList.toggle('nav-open'));
}

// ── TOC toggle (móvil) ──
function initTocToggle() {
  const btn = document.getElementById('toc-toggle');
  const toc = document.getElementById('toc');
  if (!btn || !toc) return;
  btn.addEventListener('click', () => {
    toc.classList.toggle('toc-open');
    btn.textContent = toc.classList.contains('toc-open') ? '✕ Cerrar' : '☰ Contenido';
  });
  // Cerrar al hacer clic en un link del TOC
  toc.addEventListener('click', e => {
    if (e.target.tagName === 'A') {
      toc.classList.remove('toc-open');
      btn.textContent = '☰ Contenido';
    }
  });
}

async function loadManual() {
  const key = getParam('manual');
  const meta = MANUALS[key];

  if (!meta) {
    document.getElementById('manual-content').innerHTML =
      '<p style="color:#EF4444">Manual no encontrado.</p>';
    return;
  }

  currentMeta = meta;
  document.title = meta.label + ' · CivicTrackIO';
  document.getElementById('manual-title-label').textContent = meta.label;

  // Botón MD
  const dlBtn = document.getElementById('download-btn');
  dlBtn.href = meta.file;
  dlBtn.download = meta.file.split('/').pop();

  // Botón PDF
  document.getElementById('download-pdf-btn').addEventListener('click', e => {
    e.preventDefault();
    exportPDF();
  });

  // Botón Word
  document.getElementById('download-docx-btn').addEventListener('click', e => {
    e.preventDefault();
    exportWord();
  });

  try {
    const res = await fetch(meta.file);
    if (!res.ok) throw new Error('No se pudo cargar el archivo.');
    currentMd = await res.text();

    const html = marked.parse(currentMd);
    const container = document.getElementById('manual-content');
    container.innerHTML = html;

    const headings = [];
    container.querySelectorAll('h2, h3').forEach(h => {
      const text = h.textContent.trim();
      const id = slugify(text);
      h.id = id;
      headings.push({ level: parseInt(h.tagName[1]), id, text });
    });
    buildTOC(headings);

    window.addEventListener('scroll', highlightTOC, { passive: true });
    highlightTOC();

  } catch (e) {
    document.getElementById('manual-content').innerHTML =
      `<p style="color:#EF4444">Error: ${e.message}</p>`;
  }
}

initHamburger();
initTocToggle();
loadManual();
