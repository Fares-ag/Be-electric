#!/usr/bin/env node
/**
 * Seed requestor users for mall/site companies.
 * Creates auth.users + public.users via service role.
 *
 * Usage: node supabase/scripts/seed-requestor-users.mjs [--dry-run]
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createClient } from '@supabase/supabase-js';

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

const dryRun = process.argv.includes('--dry-run');

/** company name patterns (case-insensitive substring match) */
const USERS_TO_SEED = [
  {
    companyMatch: ['al-hazm', 'al hazm', 'hazm mall'],
    fallbackName: 'Al Hazm Mall',
    fallbackId: 'company-al-hazm-mall',
    users: [
      { email: 'rasmiya@alhazm.com', name: 'Rasmiya Arsad' },
      { email: 'sofia@alhazm.com', name: 'Sofia Elotmani' },
    ],
  },
  {
    companyMatch: ['ezdan palace', 'ezdan'],
    fallbackName: 'Ezdan Palace',
    fallbackId: 'company-ezdan-palace',
    users: [
      { email: 'Engineering@ezdanpalace.qa', name: 'Engineering' },
      { email: 'Security@ezdanpalace.qa', name: 'Security Ezdan Palace' },
    ],
  },
  {
    companyMatch: ['doha festival', 'dfc'],
    fallbackName: 'Doha Festival City',
    fallbackId: 'company-doha-festival-city',
    users: [
      { email: 'Sivasubramaniyan.Ramachandran@alfuttaim.com', name: 'Sivasubramaniyan Ramachandran' },
      { email: 'Arun.Ramakrishnan@alfuttaim.com', name: 'Arun Ramakrishnan' },
    ],
  },
  {
    companyMatch: ['udc pearl', 'udc', 'pearl qatar'],
    fallbackName: 'The Pearl Qatar (UDC & AUDI)',
    fallbackId: 'company-pearl-qatar',
    users: [
      { email: 'binu.nair@udcqatar.com', name: 'Binu Nair' },
      { email: 'ittisal@udcqatar.com', name: 'Ittisal' },
    ],
  },
];

function normalize(s) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
}

function findCompany(companies, patterns) {
  const normalizedPatterns = patterns.map(normalize);
  return companies.find((c) => {
    const n = normalize(c.name);
    return normalizedPatterns.some((p) => n.includes(p) || p.includes(n));
  });
}

function tempPassword() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  let s = '';
  for (let i = 0; i < 14; i++) s += chars[Math.floor(Math.random() * chars.length)];
  return s + '!1';
}

async function ensureCompany(supabase, patterns, fallbackName, fallbackId) {
  const list = (await supabase.from('companies').select('id, name').order('name')).data ?? [];
  let company = findCompany(list, patterns);
  if (company) return company;

  const payload = {
    id: fallbackId,
    name: fallbackName,
    isActive: true,
    updatedAt: new Date().toISOString(),
  };
  if (dryRun) {
    console.log(`Would create company: ${fallbackName} (${fallbackId})`);
    return { id: fallbackId, name: fallbackName };
  }
  const { data, error } = await supabase.from('companies').insert(payload).select('id, name').single();
  if (error) throw new Error(`Create company ${fallbackName}: ${error.message}`);
  console.log(`Created company: ${data.name} (${data.id})`);
  return data;
}

const { url, serviceKey } = loadEnv();
const supabase = createClient(url, serviceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const { data: companies, error: companiesError } = await supabase
  .from('companies')
  .select('id, name')
  .order('name');
if (companiesError) throw new Error(companiesError.message);

console.log('Companies in DB:');
for (const c of companies ?? []) console.log(` - ${c.name} (${c.id})`);

const results = [];

for (const group of USERS_TO_SEED) {
  const company = await ensureCompany(
    supabase,
    group.companyMatch,
    group.fallbackName,
    group.fallbackId,
  );
  console.log(`\n=== ${company.name} (${company.id}) ===`);

  for (const u of group.users) {
    const email = u.email.trim().toLowerCase();

    const { data: existingProfile } = await supabase
      .from('users')
      .select('id, email, name, companyId')
      .eq('email', email)
      .maybeSingle();

    if (existingProfile) {
      if (existingProfile.companyId !== company.id) {
        if (dryRun) {
          console.log(`Would update company for ${email} -> ${company.name}`);
        } else {
          const { error: updErr } = await supabase
            .from('users')
            .update({ companyId: company.id, name: u.name, updatedAt: new Date().toISOString() })
            .eq('id', existingProfile.id);
          if (updErr) throw new Error(`Update ${email}: ${updErr.message}`);
          console.log(`Updated existing user ${email} -> company ${company.name}`);
        }
      } else {
        console.log(`Skip (exists): ${email}`);
      }
      results.push({ email, status: 'exists', company: company.name });
      continue;
    }

    if (dryRun) {
      console.log(`Would create: ${u.name} <${email}> @ ${company.name}`);
      results.push({ email, status: 'would_create', company: company.name });
      continue;
    }

    const password = tempPassword();
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { name: u.name, role: 'requestor' },
    });

    if (authError) {
      if (authError.message?.includes('already been registered')) {
        const { data: listData } = await supabase.auth.admin.listUsers({ page: 1, perPage: 1000 });
        const authUser = listData?.users?.find((x) => x.email?.toLowerCase() === email);
        if (!authUser) throw new Error(`Auth exists but not found: ${email}`);
        const { error: insErr } = await supabase.from('users').upsert(
          {
            id: authUser.id,
            email,
            name: u.name,
            role: 'requestor',
            isActive: true,
            companyId: company.id,
            department: null,
            updatedAt: new Date().toISOString(),
          },
          { onConflict: 'id' },
        );
        if (insErr) throw new Error(`Profile ${email}: ${insErr.message}`);
        console.log(`Linked existing auth user ${email}`);
        results.push({ email, status: 'linked', company: company.name });
        continue;
      }
      throw new Error(`Auth ${email}: ${authError.message}`);
    }

    const id = authData.user.id;
    const { error: profileError } = await supabase.from('users').upsert(
      {
        id,
        email,
        name: u.name,
        role: 'requestor',
        isActive: true,
        companyId: company.id,
        department: null,
        updatedAt: new Date().toISOString(),
      },
      { onConflict: 'id' },
    );
    if (profileError) throw new Error(`Profile ${email}: ${profileError.message}`);

    console.log(`Created ${u.name} <${email}> tempPassword=${password}`);
    results.push({ email, status: 'created', company: company.name, tempPassword: password });
  }
}

console.log('\n--- Summary ---');
for (const r of results) {
  const extra = r.tempPassword ? ` password=${r.tempPassword}` : '';
  console.log(`${r.status.padEnd(12)} ${r.email} @ ${r.company}${extra}`);
}
