const STORAGE_KEY_PREFIX = 'beelectric.notification-preferences.v1';
const LEGACY_STORAGE_KEY = 'beelectric.notification-preferences.v1';

function storageKey(userId?: string | null): string {
  const id = userId?.trim();
  return id ? `${STORAGE_KEY_PREFIX}.${id}` : LEGACY_STORAGE_KEY;
}

export type NotificationPreferences = {
  emailOnAssigned: boolean;
  emailOnCompleted: boolean;
  emailOnStatusChange: boolean;
};

export const DEFAULT_NOTIFICATION_PREFERENCES: NotificationPreferences = {
  emailOnAssigned: true,
  emailOnCompleted: true,
  emailOnStatusChange: false,
};

export function normalizeNotificationPreferences(
  parsed: Partial<NotificationPreferences> | null | undefined
): NotificationPreferences {
  if (!parsed) return DEFAULT_NOTIFICATION_PREFERENCES;
  return {
    emailOnAssigned: parsed.emailOnAssigned ?? DEFAULT_NOTIFICATION_PREFERENCES.emailOnAssigned,
    emailOnCompleted: parsed.emailOnCompleted ?? DEFAULT_NOTIFICATION_PREFERENCES.emailOnCompleted,
    emailOnStatusChange:
      parsed.emailOnStatusChange ?? DEFAULT_NOTIFICATION_PREFERENCES.emailOnStatusChange,
  };
}

export function loadNotificationPreferences(userId?: string | null): NotificationPreferences {
  if (typeof window === 'undefined') return DEFAULT_NOTIFICATION_PREFERENCES;
  try {
    const key = storageKey(userId);
    let raw = localStorage.getItem(key);
    if (!raw && userId?.trim()) {
      raw = localStorage.getItem(LEGACY_STORAGE_KEY);
      if (raw) {
        localStorage.setItem(key, raw);
        localStorage.removeItem(LEGACY_STORAGE_KEY);
      }
    }
    if (!raw) return DEFAULT_NOTIFICATION_PREFERENCES;
    return normalizeNotificationPreferences(JSON.parse(raw) as Partial<NotificationPreferences>);
  } catch {
    return DEFAULT_NOTIFICATION_PREFERENCES;
  }
}

export function saveNotificationPreferences(
  prefs: NotificationPreferences,
  userId?: string | null
): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(storageKey(userId), JSON.stringify(prefs));
}
