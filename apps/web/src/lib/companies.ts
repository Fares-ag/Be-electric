export type CompanyUsageCounts = {
  assets: number;
  users: number;
};

export function companyDeleteBlockReason(counts: CompanyUsageCounts): string | null {
  if (counts.users > 0 && counts.assets > 0) {
    return `Cannot delete: ${counts.users} user(s) and ${counts.assets} charger(s) are linked. Reassign or remove them first.`;
  }
  if (counts.users > 0) {
    return `Cannot delete: ${counts.users} user(s) are assigned to this company. Reassign them first.`;
  }
  if (counts.assets > 0) {
    return `Cannot delete: ${counts.assets} charger(s) are linked. Reassign or remove them first.`;
  }
  return null;
}

export function validateCompanyForm(input: {
  name?: string;
  contactEmail?: string | null;
}): string | null {
  if (!input.name?.trim()) return 'Company name is required';
  const email = input.contactEmail?.trim();
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return 'Enter a valid contact email';
  }
  return null;
}

export function countRowsByCompanyId(
  rows: readonly { companyId: string | null }[]
): Record<string, number> {
  return rows.reduce<Record<string, number>>((acc, row) => {
    const id = row.companyId;
    if (!id) return acc;
    acc[id] = (acc[id] ?? 0) + 1;
    return acc;
  }, {});
}
