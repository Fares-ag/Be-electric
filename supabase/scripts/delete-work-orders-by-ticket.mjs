#!/usr/bin/env node
/**
 * Delete specific work orders by ticketNumber (service role).
 * Usage: node supabase/scripts/delete-work-orders-by-ticket.mjs WO-2026-76418 ...
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '../..');

function loadEnv() {
  const envPath = path.join(repoRoot, 'apps/web/.env.local');
  if (!fs.existsSync(envPath)) throw new Error('Missing apps/web/.env.local');
  const raw = fs.readFileSync(envPath, 'utf8');
  const url = raw.match(/NEXT_PUBLIC_SUPABASE_URL=(.+)/)?.[1]?.trim();
  const serviceKey = raw.match(/SUPABASE_SERVICE_ROLE_KEY=(.+)/)?.[1]?.trim();
  if (!url || !serviceKey) throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  return { url: url.replace(/\/$/, ''), serviceKey };
}

const tickets = process.argv.slice(2);
if (tickets.length === 0) {
  console.error('Usage: node delete-work-orders-by-ticket.mjs <ticketNumber> ...');
  process.exit(1);
}

const { url, serviceKey } = loadEnv();

const headers = (extra = {}) => ({
  apikey: serviceKey,
  Authorization: `Bearer ${serviceKey}`,
  'Content-Type': 'application/json',
  ...extra,
});

function inFilter(values) {
  return values.map((v) => `"${v}"`).join(',');
}

const fetchRes = await fetch(
  `${url}/rest/v1/work_orders?select=id,ticketNumber,problemDescription,status&ticketNumber=in.(${inFilter(tickets)})`,
  { headers: headers({ Prefer: 'return=representation' }) },
);
if (!fetchRes.ok) throw new Error(`Fetch failed: ${fetchRes.status} ${await fetchRes.text()}`);

const rows = await fetchRes.json();
console.log(`Found ${rows.length} work order(s):`);
for (const r of rows) console.log(` - ${r.ticketNumber} (${r.id}) ${r.status}`);

const missing = tickets.filter((t) => !rows.some((r) => r.ticketNumber === t));
if (missing.length) console.log('Not found:', missing.join(', '));

const ids = rows.map((r) => r.id);
if (ids.length === 0) process.exit(0);

const prRes = await fetch(
  `${url}/rest/v1/parts_requests?workOrderId=in.(${inFilter(ids)})&select=id`,
  { headers: headers() },
);
if (!prRes.ok) throw new Error(`parts_requests fetch failed: ${prRes.status}`);
const pr = await prRes.json();
if (pr.length) {
  const delPr = await fetch(`${url}/rest/v1/parts_requests?workOrderId=in.(${inFilter(ids)})`, {
    method: 'DELETE',
    headers: headers(),
  });
  if (!delPr.ok) throw new Error(`parts_requests delete failed: ${delPr.status} ${await delPr.text()}`);
  console.log(`Deleted ${pr.length} parts_request(s)`);
}

const delWo = await fetch(`${url}/rest/v1/work_orders?id=in.(${inFilter(ids)})`, {
  method: 'DELETE',
  headers: headers({ Prefer: 'return=representation' }),
});
if (!delWo.ok) throw new Error(`work_orders delete failed: ${delWo.status} ${await delWo.text()}`);

const deleted = await delWo.json();
console.log(`Deleted ${deleted.length} work order(s):`);
for (const r of deleted) console.log(` - ${r.ticketNumber}`);
