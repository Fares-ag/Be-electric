/** Paginate PostgREST range queries (1000-row default cap). */
export async function fetchAllPages<T>(
  fetchPage: (from: number, to: number) => Promise<{ data: T[] | null; error: Error | null }>,
  pageSize = 1000
): Promise<T[]> {
  const rows: T[] = [];
  let page = 0;
  while (true) {
    const from = page * pageSize;
    const to = from + pageSize - 1;
    const { data, error } = await fetchPage(from, to);
    if (error) throw error;
    const batch = data ?? [];
    rows.push(...batch);
    if (batch.length < pageSize) break;
    page++;
  }
  return rows;
}
