/** Public legal page paths — keep in sync with App Store Connect and Flutter dart-define URLs. */
export const LEGAL_URLS = {
  privacy: '/privacy',
  terms: '/terms',
  support: '/support',
  accountDeletion: '/account-deletion',
} as const;

export const LEGAL_SUPPORT_EMAIL = 'support@be-maintain.com';

/** Canonical production domain referenced in legal copy and mobile app config. */
export const LEGAL_SITE_ORIGIN = 'https://www.be-maintain.com';

export const LEGAL_COMPANY = {
  name: 'Be Electric',
  addressLine1: 'Salwa Road, Building C1, 1st Floor',
  country: 'Qatar',
  governingLaw: 'State of Qatar',
} as const;

export const PUBLIC_LEGAL_PATHS = Object.values(LEGAL_URLS);

export function isPublicLegalPath(pathname: string): boolean {
  return PUBLIC_LEGAL_PATHS.includes(pathname as (typeof PUBLIC_LEGAL_PATHS)[number]);
}
