#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createClient } from '@supabase/supabase-js';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const raw = fs.readFileSync(path.join(repoRoot, 'apps/web/.env.local'), 'utf8');
const url = raw.match(/NEXT_PUBLIC_SUPABASE_URL=(.+)/)[1].trim();
const key = raw.match(/SUPABASE_SERVICE_ROLE_KEY=(.+)/)[1].trim();
const supabase = createClient(url, key);

const tickets = [
  'WO-2026-79036',
  'WO-2026-51354',
  'WO-2026-76418',
  'WO-2026-84001',
  'WO-HIST-20260514-IEGH',
  'WO-HIST-20260722-L64J',
];

const { data, error } = await supabase
  .from('work_orders')
  .select('ticketNumber,status,requestorName,createdAt,completedAt,company:companies(name)')
  .in('ticketNumber', tickets)
  .order('ticketNumber');

if (error) throw error;

for (const r of data ?? []) {
  console.log(
    `${r.ticketNumber} | ${r.status} | ${r.company?.name} | ${r.requestorName} | completed=${r.completedAt ?? 'null'}`
  );
}

const { count } = await supabase
  .from('work_orders')
  .select('id', { count: 'exact', head: true })
  .contains('metadata', { source: 'historical_bulk_import' });

console.log(`\nRows with metadata.source=historical_bulk_import: ${count ?? 0}`);
