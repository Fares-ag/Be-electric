const STORAGE_KEY = 'beelectric.notification-preferences.v1';

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

export function loadNotificationPreferences(): NotificationPreferences {
  if (typeof window === 'undefined') return DEFAULT_NOTIFICATION_PREFERENCES;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return DEFAULT_NOTIFICATION_PREFERENCES;
    return normalizeNotificationPreferences(JSON.parse(raw) as Partial<NotificationPreferences>);
  } catch {
    return DEFAULT_NOTIFICATION_PREFERENCES;
  }
}

export function saveNotificationPreferences(prefs: NotificationPreferences): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(prefs));
}
