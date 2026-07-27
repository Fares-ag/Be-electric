#!/usr/bin/env node
/**
 * Bulk import historical work orders from embedded spreadsheet rows.
 *
 * Usage (from repo root):
 *   node supabase/scripts/import-historical-work-orders.mjs --dry-run
 *   node supabase/scripts/import-historical-work-orders.mjs --execute
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '../..');

const PLACEHOLDER_ASSET_NAME = 'Historical / Unknown';

/** @type {Array<{ ticketNumber?: string; status: string; priority: string; problemDescription: string; requestorName: string; createdAt: string; updatedAt?: string; companyName: string }>} */
const ROWS = [
  {
    ticketNumber: 'WO-2026-79036',
    status: 'completed',
    priority: 'medium',
    problemDescription: 'needs monitoring relay',
    requestorName: 'Sivasubramaniyan Ramachandran',
    createdAt: '2026-07-20T12:24:01.082105+00:00',
    updatedAt: '2026-07-27T09:24:02.070065+00:00',
    companyName: 'DFC',
  },
  {
    ticketNumber: 'WO-2026-84832',
    status: 'completed',
    priority: 'medium',
    problemDescription: 'out of order, needs monitoring relay',
    requestorName: 'Sivasubramaniyan Ramachandran',
    createdAt: '2026-07-21T12:21:12.420621+00:00',
    updatedAt: '2026-07-27T09:23:05.720431+00:00',
    companyName: 'DFC',
  },
  {
    ticketNumber: 'WO-2026-36879',
    status: 'completed',
    priority: 'medium',
    problemDescription: 'barricaded due to charging error',
    requestorName: 'Sivasubramaniyan Ramachandran',
    createdAt: '2026-07-16T12:21:12.420621+00:00',
    updatedAt: '2026-07-27T09:21:13.353341+00:00',
    companyName: 'DFC',
  },
  {
    ticketNumber: 'WO-2026-66604',
    status: 'completed',
    priority: 'medium',
    problemDescription: 'barricaded due to service error',
    requestorName: 'Sivasubramaniyan Ramachandran',
    createdAt: '2026-07-16T12:20:00.702526+00:00',
    updatedAt: '2026-07-27T09:20:01.614688+00:00',
    companyName: 'DFC',
  },
  {
    ticketNumber: 'WO-2026-75496',
    status: 'completed',
    priority: 'medium',
    problemDescription: 'barricaded due to charging error',
    requestorName: 'Sivasubramaniyan Ramachandran',
    createdAt: '2026-07-10T12:08:57.135642+00:00',
    updatedAt: '2026-07-27T09:08:58.077261+00:00',
    companyName: 'DFC',
  },
  {
    ticketNumber: 'WO-2026-06041',
    status: 'completed',
    priority: 'medium',
    problemDescription: 'service out of order, replacement needed for relay',
    requestorName: 'Sivasubramaniyan Ramachandran',
    createdAt: '2026-07-23T12:06:38.371434+00:00',
    updatedAt: '2026-07-27T09:06:39.346628+00:00',
    companyName: 'DFC',
  },
  {
    ticketNumber: 'WO-2026-51354',
    status: 'open',
    priority: 'medium',
    problemDescription: 'barricaded out of order due to charging error',
    requestorName: 'Sivasubramaniyan Ramachandran',
    createdAt: '2026-07-15T12:03:32.834107+00:00',
    updatedAt: '2026-07-27T09:03:33.990017+00:00',
    companyName: 'DFC',
  },
  {
    ticketNumber: 'WO-2026-18902',
    status: 'open',
    priority: 'medium',
    problemDescription: 'replace required for monitoring relay',
    requestorName: 'Sivasubramaniyan Ramachandran',
    createdAt: '2026-07-15T12:00:43.237168+00:00',
    updatedAt: '2026-07-27T09:00:44.145276+00:00',
    companyName: 'DFC',
  },
  {
    ticketNumber: 'WO-2026-03880',
    status: 'assigned',
    priority: 'medium',
    problemDescription: 'baricaded out of order due to charging error',
    requestorName: 'Sivasubramaniyan Ramachandran',
    createdAt: '2026-07-15T11:55:48.192206+00:00',
    updatedAt: '2026-07-27T08:57:10.160848+00:00',
    companyName: 'DFC',
  },
  {
    ticketNumber: 'WO-2026-52998',
    status: 'inProgress',
    priority: 'medium',
    problemDescription: 'chargring not possible due to an error stating try again later',
    requestorName: 'Rasmiya Arsad',
    createdAt: '2026-07-27T11:43:31.790727+00:00',
    updatedAt: '2026-07-27T08:49:14.767078+00:00',
    companyName: 'AL-HAZM MALL',
  },
  {
    ticketNumber: 'WO-2026-76418',
    status: 'open',
    priority: 'medium',
    problemDescription: 'HMI Display error',
    requestorName: 'Binu Nair',
    createdAt: '2026-06-16T11:43:31.790727+00:00',
    companyName: 'Doha Oasis',
  },
  {
    ticketNumber: 'WO-2026-01567',
    status: 'open',
    priority: 'medium',
    problemDescription: 'Need Back end configuration',
    requestorName: 'Security Ezdan Palace',
    createdAt: '2026-06-17T11:43:31.790727+00:00',
    companyName: 'Ezdan Palace',
  },
  {
    ticketNumber: 'WO-2026-84001',
    status: 'completed',
    priority: 'medium',
    problemDescription: 'Charging point is not avaialable',
    requestorName: 'Sivasubramaniyan Ramachandran',
    createdAt: '2026-07-22T11:43:31.790727+00:00',
    companyName: 'DFC',
  },
  {
    status: 'open',
    priority: 'medium',
    problemDescription: 'Charger offline on OCCP',
    requestorName: 'Sivasubramaniyan Ramachandran',
    createdAt: '2026-07-22T11:43:31.790727+00:00',
    companyName: 'DFC',
  },
  {
    status: 'completed',
    priority: 'medium',
    problemDescription: 'Error message on HMI',
    requestorName: 'Sofia Elotmani',
    createdAt: '2026-05-14T11:43:31.790727+00:00',
    companyName: 'W Hotel',
  },
  {
    status: 'completed',
    priority: 'medium',
    problemDescription: 'Charging point  not avaialable',
    requestorName: 'Ittisal',
    createdAt: '2026-06-05T11:43:31.790727+00:00',
    companyName: 'Lulu Mall',
  },
  {
    status: 'completed',
    priority: 'medium',
    problemDescription: 'Charging point  not avaialable',
    requestorName: 'Ittisal',
    createdAt: '2026-06-05T11:43:31.790727+00:00',
    companyName: 'Lulu Mall',
  },
  {
    status: 'completed',
    priority: 'medium',
    problemDescription: 'Charger out of order',
    requestorName: 'Security Ezdan Palace',
    createdAt: '2026-06-14T11:43:31.790727+00:00',
    companyName: 'Ezdan Palace',
  },
];

/** Spreadsheet company label → match patterns + create fallback */
const COMPANY_DEFS = [
  { label: 'DFC', match: ['doha festival', 'dfc'], name: 'Doha Festival City', id: 'company-doha-festival-city' },
  { label: 'AL-HAZM MALL', match: ['al hazm', 'al-hazm', 'hazm mall'], name: 'Al Hazm Mall', id: 'company-al-hazm-mall' },
  { label: 'Doha Oasis', match: ['doha oasis'], name: 'Doha Oasis', id: 'company-doha-oasis' },
  { label: 'Ezdan Palace', match: ['ezdan palace', 'ezdan'], name: 'Ezdan Palace', id: 'company-ezdan-palace' },
  { label: 'W Hotel', match: ['w hotel'], name: 'W Hotel', id: 'company-w-hotel' },
  { label: 'Lulu Mall', match: ['lulu mall', 'lulu'], name: 'Lulu Mall', id: 'company-lulu-mall' },
];

const REQUESTOR_ALIASES = {
  'sivasubramaniyan ramachandran': ['sivasubramaniyan ramachandran', 'sivasubramaniyan'],
  'rasmiya arsad': ['rasmiya arsad', 'rasmiya'],
  'binu nair': ['binu nair', 'binu'],
  'security ezdan palace': ['security ezdan palace', 'security'],
  'sofia elotmani': ['sofia elotmani', 'sofia'],
  ittisal: ['ittisal'],
};

function loadEnv() {
  const envPath = path.join(repoRoot, 'apps/web/.env.local');
  if (!fs.existsSync(envPath)) throw new Error('Missing apps/web/.env.local');
  const raw = fs.readFileSync(envPath, 'utf8');
  const url = raw.match(/NEXT_PUBLIC_SUPABASE_URL=(.+)/)?.[1]?.trim();
  const serviceKey = raw.match(/SUPABASE_SERVICE_ROLE_KEY=(.+)/)?.[1]?.trim();
  if (!url || !serviceKey) throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  return { url: url.replace(/\/$/, ''), serviceKey };
}

function normalize(s) {
  return String(s ?? '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

function findCompanyDef(label) {
  const n = normalize(label);
  return COMPANY_DEFS.find((d) => normalize(d.label) === n || d.match.some((m) => n.includes(normalize(m))));
}

function findCompanyRecord(companies, def) {
  const patterns = [normalize(def.name), ...def.match.map(normalize)];
  return companies.find((c) => {
    const n = normalize(c.name);
    return patterns.some((p) => n.includes(p) || p.includes(n));
  });
}

function generateTicketNumber(createdAt) {
  const d = new Date(createdAt);
  const ymd = d.toISOString().slice(0, 10).replace(/-/g, '');
  const suffix = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `WO-HIST-${ymd}-${suffix}`;
}

function normalizeStatus(status) {
  const s = status.trim();
  if (s.toLowerCase() === 'open') return 'open';
  if (s === 'inProgress') return 'inProgress';
  return s;
}

function resolveRequestor(users, requestorName) {
  const n = normalize(requestorName);
  for (const [canonical, aliases] of Object.entries(REQUESTOR_ALIASES)) {
    if (aliases.some((a) => n.includes(normalize(a)) || normalize(a).includes(n))) {
      const user = users.find((u) => normalize(u.name).includes(canonical) || canonical.includes(normalize(u.name)));
      if (user) return user;
    }
  }
  return users.find((u) => normalize(u.name) === n || normalize(u.name).includes(n) || n.includes(normalize(u.name)));
}

async function ensureCompany(supabase, companies, def, dryRun) {
  let company = findCompanyRecord(companies, def);
  if (company) return company;

  const payload = {
    id: def.id,
    name: def.name,
    isActive: true,
    updatedAt: new Date().toISOString(),
  };

  if (dryRun) {
    console.log(`  Would create company: ${def.name} (${def.id})`);
    return { id: def.id, name: def.name };
  }

  const { data, error } = await supabase.from('companies').insert(payload).select('id, name').single();
  if (error) throw new Error(`Create company ${def.name}: ${error.message}`);
  companies.push(data);
  console.log(`  Created company: ${data.name} (${data.id})`);
  return data;
}

async function ensurePlaceholderAsset(supabase, companyId, dryRun) {
  const { data: existing } = await supabase
    .from('assets')
    .select('id, name')
    .eq('companyId', companyId)
    .eq('name', PLACEHOLDER_ASSET_NAME)
    .maybeSingle();

  if (existing) return existing.id;

  const id = randomUUID();
  const now = new Date().toISOString();
  const payload = {
    id,
    name: PLACEHOLDER_ASSET_NAME,
    companyId,
    location: 'Historical import placeholder',
    status: 'active',
    assetType: 'charger',
    createdAt: now,
    updatedAt: now,
    metadata: { source: 'historical_bulk_import' },
  };

  if (dryRun) {
    console.log(`  Would create placeholder asset for ${companyId}: ${PLACEHOLDER_ASSET_NAME}`);
    return id;
  }

  const { data, error } = await supabase.from('assets').insert(payload).select('id').single();
  if (error) throw new Error(`Create placeholder asset for ${companyId}: ${error.message}`);
  console.log(`  Created placeholder asset for ${companyId}: ${data.id}`);
  return data.id;
}

function buildWorkOrderPayload(row, ctx) {
  const status = normalizeStatus(row.status);
  const createdAt = row.createdAt;
  const updatedAt = row.updatedAt ?? row.createdAt;
  const isCompleted = status === 'completed' || status === 'closed';
  const completedAt = isCompleted ? (row.updatedAt ?? row.createdAt) : null;

  const ticketNumber = row.ticketNumber?.trim() || generateTicketNumber(row.createdAt);

  return {
    id: randomUUID(),
    ticketNumber,
    problemDescription: row.problemDescription.trim(),
    status,
    priority: row.priority || 'medium',
    requestorId: ctx.requestor.id,
    requestorName: ctx.requestor.name,
    companyId: ctx.company.id,
    assetId: ctx.assetId,
    createdAt,
    updatedAt,
    completedAt,
    closedAt: status === 'closed' ? completedAt : null,
    metadata: {
      source: 'historical_bulk_import',
      importedAt: new Date().toISOString(),
      spreadsheetCompany: row.companyName,
    },
  };
}

const args = new Set(process.argv.slice(2));
const dryRun = args.has('--dry-run') || !args.has('--execute');
if (!dryRun && !args.has('--execute')) {
  console.error('Pass --dry-run (default) or --execute');
  process.exit(1);
}

const { url, serviceKey } = loadEnv();
const supabase = createClient(url, serviceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

console.log(dryRun ? '=== DRY RUN ===' : '=== EXECUTE ===');
console.log(`Rows to process: ${ROWS.length}\n`);

const { data: companies, error: companiesError } = await supabase.from('companies').select('id, name').order('name');
if (companiesError) throw new Error(companiesError.message);

const { data: users, error: usersError } = await supabase.from('users').select('id, name, email, role').order('name');
if (usersError) throw new Error(usersError.message);

const { data: existingTickets } = await supabase.from('work_orders').select('ticketNumber');
const ticketSet = new Set((existingTickets ?? []).map((r) => r.ticketNumber));

const assetCache = new Map();
const results = [];

for (let i = 0; i < ROWS.length; i++) {
  const row = ROWS[i];
  const rowNum = i + 1;
  console.log(`--- Row ${rowNum}: ${row.ticketNumber || '(auto ticket)'} ---`);

  const def = findCompanyDef(row.companyName);
  if (!def) throw new Error(`Unknown company label: ${row.companyName}`);

  const company = await ensureCompany(supabase, companies ?? [], def, dryRun);

  const requestor = resolveRequestor(users ?? [], row.requestorName);
  if (!requestor) throw new Error(`Requestor not found: ${row.requestorName}`);

  let assetId = assetCache.get(company.id);
  if (!assetId) {
    assetId = await ensurePlaceholderAsset(supabase, company.id, dryRun);
    assetCache.set(company.id, assetId);
  }

  const payload = buildWorkOrderPayload(row, { company, requestor, assetId });

  if (ticketSet.has(payload.ticketNumber)) {
    console.log(`  SKIP (ticket exists): ${payload.ticketNumber}`);
    results.push({ rowNum, ticketNumber: payload.ticketNumber, status: 'skipped' });
    continue;
  }

  console.log(`  Company: ${company.name}`);
  console.log(`  Requestor: ${requestor.name} (${requestor.email})`);
  console.log(`  Status: ${payload.status} | created: ${payload.createdAt} | completed: ${payload.completedAt ?? '—'}`);
  console.log(`  Ticket: ${payload.ticketNumber}`);

  if (!dryRun) {
    const { error: insertError } = await supabase.from('work_orders').insert(payload);
    if (insertError) throw new Error(`Insert ${payload.ticketNumber}: ${insertError.message}`);
    ticketSet.add(payload.ticketNumber);
    console.log(`  INSERTED ${payload.ticketNumber}`);
  }

  results.push({ rowNum, ticketNumber: payload.ticketNumber, status: dryRun ? 'would_insert' : 'inserted' });
}

console.log('\n=== Summary ===');
for (const r of results) {
  console.log(`Row ${String(r.rowNum).padStart(2)}  ${r.status.padEnd(12)}  ${r.ticketNumber}`);
}
console.log(`\nTotal: ${results.filter((r) => r.status === 'inserted' || r.status === 'would_insert').length} inserted/would insert, ${results.filter((r) => r.status === 'skipped').length} skipped`);
