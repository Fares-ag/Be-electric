'use client';

import { Search } from 'lucide-react';
import { cn } from '@/lib/utils';

interface SearchFilterBarProps {
  search: string;
  onSearchChange: (v: string) => void;
  placeholder?: string;
  className?: string;
  children?: React.ReactNode;
}

export function SearchFilterBar({
  search,
  onSearchChange,
  placeholder = 'Search...',
  className,
  children,
}: SearchFilterBarProps) {
  return (
    <div className={cn('flex flex-col sm:flex-row gap-3 sm:items-center', className)}>
      <div className="relative flex-1 min-w-0 max-w-md">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <input
          type="search"
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder={placeholder}
          className="w-full rounded-lg border border-border bg-background pl-9 pr-3 py-2 text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
          aria-label="Search"
        />
      </div>
      {children}
    </div>
  );
}
