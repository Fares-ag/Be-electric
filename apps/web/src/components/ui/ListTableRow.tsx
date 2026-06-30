import Link from 'next/link';
import { ChevronRight } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { cn } from '@/lib/utils';

export function ListTableRow({
  href,
  children,
  className,
}: {
  href: string;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <tr className={cn('group transition-colors hover:bg-muted/40', className)}>
      {children}
      <td className="w-12 text-right">
        <Link href={href} className="inline-flex">
          <Button
            variant="outline"
            size="sm"
            className="gap-1 opacity-100 transition-opacity sm:opacity-0 sm:group-hover:opacity-100 sm:group-focus-within:opacity-100"
          >
            View
            <ChevronRight className="h-4 w-4" aria-hidden />
          </Button>
        </Link>
      </td>
    </tr>
  );
}
