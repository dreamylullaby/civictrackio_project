const MANUALS = {
  usuario: {
    label: 'Manual de usuario final · App móvil',
    file: 'manuales/CivicTrackIO - Manual de usuario final (App móvil).md',
  },
  admin: {
    label: 'Manual de administrador · Dashboard web',
    file: 'manuales/CivicTrackIO - Manual de administrador (Dashboard web).md',
  },
  tecnico: {
    label: 'Manual técnico · Instalación y configuración',
    file: 'manuales/CivicTrackIO - Manual técnico de instalación y configuración (Developer).md',
  },
  despliegue: {
    label: 'Manual de despliegue · Render · Netlify · Supabase',
    file: 'manuales/CivicTrackIO - Manual de despliegue.md',
  },
};

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

async function loadManual() {
  const key = getParam('manual');
  const meta = MANUALS[key];

  if (!meta) {
    document.getElementById('manual-content').innerHTML =
      '<p style="color:#EF4444">Manual no encontrado.</p>';
    return;
  }

  document.title = meta.label + ' · CivicTrackIO';
  document.getElementById('manual-title-label').textContent = meta.label;
  document.getElementById('download-btn').href = meta.file;
  document.getElementById('download-btn').download = meta.file.split('/').pop();

  try {
    const res = await fetch(meta.file);
    if (!res.ok) throw new Error('No se pudo cargar el archivo.');
    const md = await res.text();

    // Renderizar con marked
    const html = marked.parse(md);
    const container = document.getElementById('manual-content');
    container.innerHTML = html;

    // Agregar IDs a headings y construir TOC
    const headings = [];
    container.querySelectorAll('h2, h3').forEach(h => {
      const text = h.textContent.trim();
      const id = slugify(text);
      h.id = id;
      headings.push({ level: parseInt(h.tagName[1]), id, text });
    });
    buildTOC(headings);

    // Scroll spy
    window.addEventListener('scroll', highlightTOC, { passive: true });
    highlightTOC();

  } catch (e) {
    document.getElementById('manual-content').innerHTML =
      `<p style="color:#EF4444">Error: ${e.message}</p>`;
  }
}

loadManual();
