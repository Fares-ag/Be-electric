import { useState, useMemo } from 'react';

export function usePagination<T>(
  items: T[] | undefined,
  defaultPageSize = 10
): {
  page: number;
  setPage: (p: number) => void;
  pageSize: number;
  setPageSize: (n: number) => void;
  paginatedItems: T[];
  totalItems: number;
} {
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(defaultPageSize);

  const list = items ?? [];
  const totalItems = list.length;

  const paginatedItems = useMemo(() => {
    const start = (page - 1) * pageSize;
    return list.slice(start, start + pageSize);
  }, [list, page, pageSize]);

  return {
    page,
    setPage,
    pageSize,
    setPageSize,
    paginatedItems,
    totalItems,
  };
}
