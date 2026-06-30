import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { dismissUiHint, isUiHintDismissed, resetAllUiHints } from '@/lib/ui-hints';

const STORAGE_KEY = 'beelectric.ui-hints.v1';

describe('ui-hints', () => {
  beforeEach(() => {
    const store = new Map<string, string>();
    vi.stubGlobal('localStorage', {
      getItem: (key: string) => store.get(key) ?? null,
      setItem: (key: string, value: string) => {
        store.set(key, value);
      },
      removeItem: (key: string) => {
        store.delete(key);
      },
    });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('starts undismissed', () => {
    expect(isUiHintDismissed('pm-schedules-overview')).toBe(false);
  });

  it('persists dismiss state', () => {
    dismissUiHint('support-inbox-overview');
    expect(isUiHintDismissed('support-inbox-overview')).toBe(true);
    expect(isUiHintDismissed('pm-schedules-overview')).toBe(false);
  });

  it('clears all dismissed hints', () => {
    dismissUiHint('dashboard-command-center');
    resetAllUiHints();
    expect(isUiHintDismissed('dashboard-command-center')).toBe(false);
  });
});
