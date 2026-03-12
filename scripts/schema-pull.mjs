#!/usr/bin/env node
/**
 * Pull schema and types from linked Supabase project.
 *
 * - Types: supabase gen types typescript --linked → supabase/database.types.ts
 * - Schema (optional): supabase db pull --linked → supabase/migrations/*.sql (requires Docker)
 *
 * Usage:
 *   node scripts/schema-pull.mjs          # types only
 *   node scripts/schema-pull.mjs --schema  # types + db pull
 */

import { spawnSync } from 'child_process';
import { writeFileSync } from 'fs';
import { join } from 'path';

const root = process.cwd();
const typesPath = join(root, 'supabase', 'database.types.ts');

console.log('Generating TypeScript types from linked Supabase project...\n');
const result = spawnSync('npx', ['supabase', 'gen', 'types', 'typescript', '--linked'], {
  cwd: root,
  encoding: null,
  stdio: ['inherit', 'pipe', 'pipe'],
  timeout: 120000,
});
const buf = result.stdout;
const err = (result.stderr || Buffer.alloc(0)).toString('utf8').trim();
if (!buf || buf.length < 500) {
  console.error('supabase gen types failed or produced no output (status=%s)', result.status);
  if (err) console.error('stderr:', err.slice(0, 500));
  process.exit(1);
}
let str = buf.toString('utf8');
str = str.replace(/^Initialising login role\\.\\.\\.\r?\n/, '').trim();
writeFileSync(typesPath, str, 'utf8');
if (err) console.warn('(CLI stderr):', err.slice(0, 200));
console.log('Written:', typesPath);

if (process.argv.includes('--schema')) {
  console.log('\nPulling remote schema (requires Docker)...\n');
  run('npx supabase db pull --linked', { stdio: 'inherit' });
  console.log('\nSchema written to supabase/migrations/');
} else {
  console.log('\nTo pull the full schema as a migration, run: npm run schema:pull -- --schema');
}
