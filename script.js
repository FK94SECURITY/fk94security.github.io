const form = document.getElementById('scanForm');
const result = document.getElementById('scanResult');

function render(obj) {
  result.textContent = JSON.stringify(obj, null, 2);
}

function normalizeBase(base) {
  if (!base) return '';
  return base.replace(/\/$/, '');
}

form?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = document.getElementById('email').value.trim().toLowerCase();
  const base = normalizeBase(document.getElementById('apiBase').value.trim());

  if (!email) return;

  render({ status: 'running', message: 'Ejecutando diagnóstico…' });

  const endpoints = [
    `${base}/api/v1/intel/email`,
    '/api/v1/intel/email',
    '/api/v1/demo'
  ].filter(Boolean);

  for (const endpoint of endpoints) {
    try {
      const isDemo = endpoint.endsWith('/api/v1/demo');
      const res = await fetch(endpoint, {
        method: isDemo ? 'GET' : 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: isDemo ? undefined : JSON.stringify({ email }),
      });

      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      render({ endpoint, ok: true, data });
      return;
    } catch (err) {
      render({ endpoint, ok: false, error: err.message, tryingNext: true });
    }
  }

  render({
    ok: false,
    error: 'No se pudo conectar al backend.',
    hint: 'Cargá URL en "Backend API" o deployá backend-simple para usar API real.'
  });
});
