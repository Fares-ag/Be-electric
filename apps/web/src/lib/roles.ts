import type { User } from '@beelectric/supabase';

export type AppRole = User['role'];

export function isAdminRole(role: AppRole | undefined): boolean {
  return role === 'admin' || role === 'manager';
}

export function isRequestorRole(role: AppRole | undefined): boolean {
  return role === 'requestor';
}

export function isTechnicianRole(role: AppRole | undefined): boolean {
  return role === 'technician';
}

/** Routes visible in admin sidebar — require admin or manager role. */
export const ADMIN_ROUTE_PREFIXES = [
  '/dashboard',
  '/work-orders',
  '/pm-tasks',
  '/pm-schedules',
  '/assets',
  '/users',
  '/companies',
  '/inventory',
  '/parts-requests',
  '/purchase-orders',
  '/support-requests',
  '/analytics',
  '/reports',
  '/settings',
] as const;

/** Routes for requestor web experience. */
export const REQUESTOR_ROUTE_PREFIXES = [
  '/request',
  '/my-requests',
  '/requestor-analytics',
  '/notification-settings',
] as const;

/** Accessible by any authenticated web role (except technician gate). */
export const SHARED_ROUTE_PREFIXES = ['/notifications'] as const;

function matchesPrefix(pathname: string, prefixes: readonly string[]): boolean {
  return prefixes.some((p) => pathname === p || pathname.startsWith(`${p}/`));
}

export function isAdminRoute(pathname: string): boolean {
  return matchesPrefix(pathname, ADMIN_ROUTE_PREFIXES);
}

export function isRequestorRoute(pathname: string): boolean {
  return matchesPrefix(pathname, REQUESTOR_ROUTE_PREFIXES);
}

export function isSharedRoute(pathname: string): boolean {
  return matchesPrefix(pathname, SHARED_ROUTE_PREFIXES);
}

/** Requestors may open a single work order they submitted (not the admin list). */
export function isWorkOrderDetailRoute(pathname: string): boolean {
  return /^\/work-orders\/[^/]+$/.test(pathname);
}

export function canAccessRoute(pathname: string, role: AppRole | undefined): boolean {
  if (!role) return false;
  if (isTechnicianRole(role)) return false;
  if (isSharedRoute(pathname)) return true;
  if (isAdminRole(role)) return isAdminRoute(pathname) || isSharedRoute(pathname);
  if (isRequestorRole(role)) {
    return isRequestorRoute(pathname) || isSharedRoute(pathname) || isWorkOrderDetailRoute(pathname);
  }
  return false;
}

export function defaultHomeForRole(role: AppRole | undefined): string {
  if (isAdminRole(role)) return '/dashboard';
  if (isRequestorRole(role)) return '/my-requests';
  if (isTechnicianRole(role)) return '/dashboard';
  return '/login';
}

export function redirectForUnauthorizedRoute(pathname: string, role: AppRole | undefined): string | null {
  if (!role || isTechnicianRole(role)) return null;
  if (canAccessRoute(pathname, role)) return null;
  return defaultHomeForRole(role);
}
