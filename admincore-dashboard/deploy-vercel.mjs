import { readdirSync, statSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const token = process.env.VERCEL_TOKEN;
const teamId = process.env.VERCEL_TEAM_ID;
const projectId = process.env.VERCEL_PROJECT_ID;
const dir = process.argv[2] || 'dist';

if (!token || !teamId || !projectId) {
  console.error('Missing env: VERCEL_TOKEN, VERCEL_TEAM_ID, VERCEL_PROJECT_ID');
  process.exit(1);
}

const api = (path, opts = {}) =>
  fetch(`https://api.vercel.com${path}${path.includes('?') ? '&' : '?'}teamId=${teamId}`, {
    ...opts,
    headers: { Authorization: `Bearer ${token}`, ...(opts.headers || {}) },
  });

function walk(d, base = '') {
  let out = [];
  for (const e of readdirSync(d)) {
    const full = join(d, e);
    const rel = base ? `${base}/${e}` : e;
    if (statSync(full).isDirectory()) out = out.concat(walk(full, rel));
    else out.push({ full, rel });
  }
  return out;
}

const entries = walk(dir);
const files = entries.map((f) => {
  const data = readFileSync(f.full).toString('base64');
  return { file: f.rel, data, encoding: 'base64' };
});

console.log(`Collected ${files.length} files`);

const dep = await api('/v13/deployments', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    name: 'admincore-dashboar',
    target: 'production',
    source: 'cli',
    buildCommand: null,
    outputDirectory: null,
    framework: null,
    files,
  }),
});
const d = await dep.json();
if (!dep.ok) {
  console.error('deploy failed', dep.status, d);
  process.exit(1);
}
console.log('DEPLOYED', d.url, d.id);
