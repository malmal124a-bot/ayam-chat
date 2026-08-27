// ============================================================
// Seed Firestore collections for the admin dashboard.
//
// Reads `INSERT INTO` seed statements from the Supabase SQL
// migrations (root `supabase/migrations/*.sql`) and writes the
// rows into the SAME Firestore collections the Flutter app and
// the admin dashboard now use.
//
// Usage:
//   1. Enable Firebase Admin: download the service-account JSON
//      from Firebase Console -> Project settings -> Service accounts
//      and save it as `scripts/serviceAccount.json` (or point the
//      GOOGLE_APPLICATION_CREDENTIALS env var at it).
//   2. npm install
//   3. npm run seed:firestore
//
// Optional bootstrap: make the currently logged-in admin an admin in
// Firestore rules (rules require a doc in `admin_users/{authUid}`):
//   ADMIN_UID=<auth-uid> ADMIN_EMAIL=<email> ADMIN_NAME=<name> npm run seed:firestore
//
// Firestore is schemaless, so this script both *creates* the
// collections (tables) and fills them with the seed data.
// Collections without SQL seed data are created lazily by the
// dashboard itself when the admin first saves a record.
// ============================================================
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const __dirname = dirname(fileURLToPath(import.meta.url));
const MIGRATIONS_DIR = resolve(__dirname, '../../supabase/migrations');

const FILES = [
  '20250610_gift_categories_banner.sql', // gift_categories
  '20250615_app_assets.sql', // app_assets
  '20250615_seed_app_assets.sql', // app_assets
  '20250618_seed_referenced_assets.sql', // app_assets
  '20260622_cp_features.sql', // cp_settings, cp_gifts, cp_cars
  '20260628_cp_rank_rewards.sql', // cp_rank_rewards
  '20260730_weekly_signin.sql', // signin_rewards
];

// Which column holds the Firestore document ID for each table.
const KEY_FIELDS = {
  users: 'uid',
  rooms: 'room_id',
  store_items: 'item_id',
  app_config: 'key',
  cp_settings: 'key',
  level_config: 'type_level',
  vip_config: 'tier',
  gift_categories: 'id',
  signin_rewards: 'day_number',
};

function md5(s) {
  return createHash('md5').update(s).digest('hex');
}

function docIdFor(table, row) {
  const kf = KEY_FIELDS[table];
  if (kf && row[kf] != null) return String(row[kf]);
  if (row.id != null) return String(row.id);
  if (row.uuid != null) return String(row.uuid);
  return 'seed_' + md5(JSON.stringify(row)).slice(0, 20);
}

// Parse one SQL value literal into a JS value.
function parseValue(raw) {
  const v = raw.trim();
  if (v === 'NULL') return undefined;
  if (v === 'true') return true;
  if (v === 'false') return false;
  if (/^-?\d+(\.\d+)?$/.test(v)) return Number(v);
  if (v.startsWith("'")) {
    return v.slice(1, v.length - 1).replace(/''/g, "'");
  }
  // functions / uuid / casts / timestamps -> drop
  return undefined;
}

// Split `VALUES (...),(...),...` into per-row groups (paren-aware, quote-aware).
function splitRows(valsPart) {
  const groups = [];
  let i = 0;
  while (i < valsPart.length) {
    while (i < valsPart.length && valsPart[i] !== '(') i++;
    if (i >= valsPart.length) break;
    let depth = 0;
    let inStr = false;
    const start = i;
    while (i < valsPart.length) {
      const c = valsPart[i];
      if (inStr) {
        if (c === "'") {
          if (valsPart[i + 1] === "'") { i += 2; continue; }
          inStr = false;
        }
        i++;
        continue;
      }
      if (c === "'") inStr = true;
      else if (c === '(') depth++;
      else if (c === ')') {
        depth--;
        if (depth === 0) { i++; break; }
      }
      i++;
    }
    groups.push(valsPart.slice(start, i));
  }
  return groups;
}

// Split one row group `(...)` into value tokens (comma-aware, quote-aware).
function splitRow(rowText) {
  const inner = rowText.slice(1, -1);
  const tokens = [];
  let i = 0;
  while (i < inner.length) {
    while (i < inner.length && /\s/.test(inner[i])) i++;
    if (i >= inner.length) break;
    const start = i;
    if (inner[i] === "'") {
      i++;
      while (i < inner.length) {
        if (inner[i] === "'") {
          if (inner[i + 1] === "'") { i += 2; continue; }
          i++;
          break;
        }
        i++;
      }
    } else {
      while (i < inner.length && inner[i] !== ',') i++;
    }
    tokens.push(inner.slice(start, i));
    if (i < inner.length) i++;
  }
  return tokens;
}

// Extract `INSERT INTO tbl (cols) VALUES ...;` statements.
function extractInserts(sql) {
  const statements = [];
  const re = /INSERT\s+INTO\s+(?:public\.)?([a-z_]+)\s*\(([^)]+)\)\s+VALUES\s*([\s\S]*?);/gi;
  let m;
  while ((m = re.exec(sql)) !== null) {
    const table = m[1];
    const cols = m[2].split(',').map(c => c.trim().replace(/^"|"$/g, ''));
    const rowsText = splitRows(m[3]);
    for (const rt of rowsText) {
      const tokens = splitRow(rt);
      if (tokens.length !== cols.length) continue;
      const row = {};
      cols.forEach((col, idx) => {
        const val = parseValue(tokens[idx]);
        if (val !== undefined) row[col] = val;
      });
      statements.push({ table, row });
    }
  }
  return statements;
}

// ---- main ----

let admin;
try {
  admin = await import('firebase-admin');
} catch {
  console.error('firebase-admin is not installed. Run: npm install firebase-admin');
  process.exit(1);
}

const credFile =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  join(__dirname, 'serviceAccount.json');

if (!existsSync(credFile)) {
  console.error(
    'Service-account JSON not found at ' + credFile +
    '\nDownload it from Firebase Console -> Project settings -> Service accounts' +
    '\nand save it as scripts/serviceAccount.json (or set GOOGLE_APPLICATION_CREDENTIALS).',
  );
  process.exit(1);
}

const app = admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(readFileSync(credFile, 'utf8'))),
});
const db = app.firestore();

let total = 0;
const byTable = {};

for (const file of FILES) {
  const path = join(MIGRATIONS_DIR, file);
  if (!existsSync(path)) { console.log(`skip (missing): ${file}`); continue; }
  const sql = readFileSync(path, 'utf8');
  const stmts = extractInserts(sql);
  for (const { table, row } of stmts) {
    const id = docIdFor(table, row);
    await db.collection(table).doc(id).set(row, { merge: true });
    total++;
    byTable[table] = (byTable[table] ?? 0) + 1;
  }
  console.log(`seeded ${file}: ${stmts.length} rows`);
}

console.log('\nDone. Rows written: ' + total);
for (const [t, n] of Object.entries(byTable)) console.log(`  ${t}: ${n}`);

// Touch empty but expected collections so they show up in the console
// (placeholder doc is removed again immediately).
const TOUCH = [
  'gifts', 'store_items', 'app_config', 'bug_reports', 'level_config',
  'vip_config', 'badges', 'necklaces', 'gifted_items', 'unions',
  'cps', 'bds', 'sent_gifts', 'notifications', 'reports',
  'host_agencies', 'host_agency_members', 'commission_settings',
  'host_milestones', 'host_agency_join_requests', 'agency_diamond_ledger',
  'agency_withdrawal_requests', 'user_vips', 'ranking_frames', 'gift_banner_configs',
];
for (const col of TOUCH) {
  try {
    const ref = db.collection(col).doc('_meta');
    await ref.set({ init: true });
    await ref.delete();
  } catch { /* ignore */ }
}
console.log('\nExpected empty collections touched (they now exist).');

// ---- Admin bootstrap ----
// Firestore rules gate admin writes on `admin_users/{authUid}` existing.
// The Admin SDK bypasses rules, so this is the only place that can create
// the first admin. Run with:
//   ADMIN_UID=<auth-uid> ADMIN_EMAIL=<email> ADMIN_NAME=<name> npm run seed:firestore
if (process.env.ADMIN_UID) {
  const adminUid = process.env.ADMIN_UID;
  const existing = await db.collection('admin_users').doc(adminUid).get();
  if (existing.exists) {
    console.log(`admin_users/${adminUid} already exists — skipped.`);
  } else {
    await db.collection('admin_users').doc(adminUid).set({
      uid: adminUid,
      email: process.env.ADMIN_EMAIL || '',
      display_name: process.env.ADMIN_NAME || 'Super Admin',
      role: 'super_admin',
      permissions: { all: true },
      is_active: true,
      created_at: new Date().toISOString(),
    });
    console.log(`Created admin_users/${adminUid} (super admin).`);
  }
}

console.log('\nDone.');
process.exit(0);
