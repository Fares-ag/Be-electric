#!/usr/bin/env node
/**
 * Clear operational CMMS data on linked Supabase (production).
 * KEEPS: companies, assets, users, admin_users, schema/RLS.
 * See clear-operational-data.sql for table list.
 *
 * Usage (from repo root):
 *   node supabase/scripts/clear-operational-data.mjs --dry-run
 *   node supabase/scripts/clear-operational-data.mjs --execute
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

const TABLES_TO_CLEAR = [
  'pm_task_occurrences',
  'pm_schedules',
  'pm_tasks',
  'parts_requests',
  'work_orders',
  'support_requests',
  'notifications',
  'purchase_orders',
  'inventory_items',
  'vendors',
  'audit_events',
  'escalation_events',
  'workflows',
];

const PRESERVE_TABLES = ['companies', 'assets', 'users', 'admin_users'];

const STORAGE_BUCKETS = ['files', 'work-order-photos'];

const STORAGE_PREFIXES = [
  'work_orders',
  'pm_occurrences',
  'pm_tasks',
  'support_requests',
];

const args = new Set(process.argv.slice(2));
const dryRun = args.has('--dry-run') || !args.has('--execute');
if (!dryRun && !args.has('--execute')) {
  console.error('Pass --dry-run (default) or --execute');
  process.exit(1);
}

const { url, serviceKey } = loadEnv();

function restHeaders(extra = {}) {
  return {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    ...extra,
  };
}

async function countTable(table) {
  const countColumn = table === 'admin_users' ? 'email' : 'id';
  const res = await fetch(`${url}/rest/v1/${table}?select=${countColumn}&limit=1`, {
    headers: {
      ...restHeaders(),
      Prefer: 'count=exact',
    },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`count ${table}: ${res.status} ${text}`);
  }
  const range = res.headers.get('content-range') ?? '';
  const match = range.match(/\/(\d+)$/);
  return match ? Number(match[1]) : 0;
}

async function deleteAllRows(table) {
  const res = await fetch(`${url}/rest/v1/${table}?id=not.is.null`, {
    method: 'DELETE',
    headers: restHeaders({ Prefer: 'return=minimal' }),
  });
  if (res.status === 204 || res.status === 200) return;
  const text = await res.text();
  throw new Error(`delete ${table}: ${res.status} ${text}`);
}

async function resetAssetMaintenanceDates() {
  const res = await fetch(`${url}/rest/v1/assets?id=not.is.null`, {
    method: 'PATCH',
    headers: restHeaders({
      'Content-Type': 'application/json',
      Prefer: 'return=minimal',
    }),
    body: JSON.stringify({
      lastMaintenanceDate: null,
      nextMaintenanceDate: null,
      updatedAt: new Date().toISOString(),
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`reset assets: ${res.status} ${text}`);
  }
}

async function listStorageObjects(bucket, prefix = '') {
  const res = await fetch(`${url}/storage/v1/object/list/${bucket}`, {
    method: 'POST',
    headers: restHeaders({ 'Content-Type': 'application/json' }),
    body: JSON.stringify({
      prefix,
      limit: 1000,
      offset: 0,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`list storage ${bucket}/${prefix}: ${res.status} ${text}`);
  }
  return res.json();
}

async function deleteStorageObject(bucket, objectPath) {
  const encoded = objectPath.split('/').map(encodeURIComponent).join('/');
  const res = await fetch(`${url}/storage/v1/object/${bucket}/${encoded}`, {
    method: 'DELETE',
    headers: restHeaders(),
  });
  if (res.status === 200 || res.status === 204) return;
  const text = await res.text();
  throw new Error(`delete storage ${bucket}/${objectPath}: ${res.status} ${text}`);
}

async function collectFilesRecursive(bucket, prefix) {
  const entries = await listStorageObjects(bucket, prefix);
  const files = [];
  for (const entry of entries) {
    const name = entry.name;
    const fullPath = prefix ? `${prefix}/${name}` : name;
    if (entry.id) {
      files.push(fullPath);
    } else {
      const nested = await collectFilesRecursive(bucket, fullPath);
      files.push(...nested);
    }
  }
  return files;
}

async function clearStoragePrefixes(bucket) {
  let deleted = 0;
  for (const prefix of STORAGE_PREFIXES) {
    const files = await collectFilesRecursive(bucket, prefix);
    for (const filePath of files) {
      if (dryRun) {
        console.log(`  [dry-run] would delete ${bucket}/${filePath}`);
      } else {
        await deleteStorageObject(bucket, filePath);
      }
      deleted += 1;
    }
  }
  return deleted;
}

async function clearLegacyBucket(bucket) {
  const files = await collectFilesRecursive(bucket, '');
  for (const filePath of files) {
    if (dryRun) {
      console.log(`  [dry-run] would delete ${bucket}/${filePath}`);
    } else {
      await deleteStorageObject(bucket, filePath);
    }
  }
  return files.length;
}

async function printReport(label) {
  console.log(`\n=== ${label} ===`);
  for (const table of [...TABLES_TO_CLEAR, ...PRESERVE_TABLES]) {
    const count = await countTable(table);
    const tag = PRESERVE_TABLES.includes(table) ? '(KEEP)' : '(cleared)';
    console.log(`${table.padEnd(24)} ${String(count).padStart(6)} ${tag}`);
  }
}

async function main() {
  console.log(`Target: ${url}`);
  console.log(`Mode: ${dryRun ? 'DRY RUN' : 'EXECUTE'}`);

  await printReport('BEFORE');

  if (dryRun) {
    console.log('\nWould DELETE all rows from:', TABLES_TO_CLEAR.join(', '));
    console.log('Would RESET assets.lastMaintenanceDate / nextMaintenanceDate');
    console.log('Would DELETE storage prefixes:', STORAGE_PREFIXES.join(', '));
    console.log('Would DELETE all objects in bucket: work-order-photos');
    console.log('\nRe-run with --execute to apply.');
    return;
  }

  console.log('\nDeleting operational tables...');
  for (const table of TABLES_TO_CLEAR) {
    await deleteAllRows(table);
    console.log(`  cleared ${table}`);
  }

  console.log('\nResetting asset maintenance dates...');
  await resetAssetMaintenanceDates();
  console.log('  assets updated');

  console.log('\nClearing storage (files bucket)...');
  const filesDeleted = await clearStoragePrefixes('files');
  console.log(`  deleted ${filesDeleted} objects under operational prefixes`);

  console.log('\nClearing storage (work-order-photos bucket)...');
  const legacyDeleted = await clearLegacyBucket('work-order-photos');
  console.log(`  deleted ${legacyDeleted} legacy objects`);

  await printReport('AFTER');
  console.log('\nDone.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
