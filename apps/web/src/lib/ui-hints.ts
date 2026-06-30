export type UiHintKey =
  | 'dashboard-command-center'
  | 'pm-schedules-overview'
  | 'support-inbox-overview'
  | 'inventory-overview'
  | 'parts-requests-overview'
  | 'pm-tasks-legacy'
  | 'notifications-overview';

const STORAGE_KEY = 'beelectric.ui-hints.v1';

function hasStorage(): boolean {
  return typeof localStorage !== 'undefined';
}

function readDismissedMap(): Record<string, boolean> {
  if (!hasStorage()) return {};
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return {};
    return JSON.parse(raw) as Record<string, boolean>;
  } catch {
    return {};
  }
}

export function isUiHintDismissed(key: UiHintKey): boolean {
  return !!readDismissedMap()[key];
}

export function dismissUiHint(key: UiHintKey): void {
  if (!hasStorage()) return;
  try {
    const dismissed = readDismissedMap();
    dismissed[key] = true;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(dismissed));
  } catch {
    // Ignore quota or parse errors — hint stays visible.
  }
}

export function resetAllUiHints(): void {
  if (!hasStorage()) return;
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch {
    // Ignore quota errors.
  }
}
