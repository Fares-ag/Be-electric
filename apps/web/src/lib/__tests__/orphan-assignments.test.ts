import { describe, expect, it } from 'vitest';
import {
  collectOrphanIds,
  mergeOrphanIds,
  scrubAssigneeList,
} from '@/lib/orphan-assignments';

describe('orphan-assignments', () => {
  const known = new Set(['user-a', 'user-b']);

  it('finds assignee IDs missing from users table', () => {
    expect(collectOrphanIds(['user-a', 'deleted-1'], known)).toEqual(['deleted-1']);
    expect(collectOrphanIds([], known)).toEqual([]);
    expect(collectOrphanIds(null, known)).toEqual([]);
  });

  it('includes orphan primary technician IDs', () => {
    expect(
      mergeOrphanIds(['user-a'], 'deleted-primary', known)
    ).toEqual(['deleted-primary']);
    expect(mergeOrphanIds(['user-a', 'deleted-2'], 'user-b', known)).toEqual(['deleted-2']);
  });

  it('scrubs orphan IDs and optionally adds replacement', () => {
    expect(scrubAssigneeList(['user-a', 'orphan'], ['orphan'])).toEqual(['user-a']);
    expect(scrubAssigneeList(['user-a', 'orphan'], ['orphan'], 'user-b')).toEqual([
      'user-a',
      'user-b',
    ]);
    expect(scrubAssigneeList(['user-a'], ['orphan'], 'user-a')).toEqual(['user-a']);
  });
});
