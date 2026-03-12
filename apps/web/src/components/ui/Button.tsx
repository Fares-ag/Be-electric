import { cn } from '@/lib/utils';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive';
  size?: 'sm' | 'md' | 'lg';
}

export function Button({
  className,
  variant = 'primary',
  size = 'md',
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(
        'inline-flex items-center justify-center rounded-lg font-medium transition-all duration-200',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2',
        'disabled:pointer-events-none disabled:opacity-50',
        variant === 'primary' && 'bg-primary text-primary-foreground shadow-button-primary hover:bg-primary-hover active:scale-[0.98]',
        variant === 'secondary' && 'bg-muted text-muted-foreground hover:bg-muted/80',
        variant === 'outline' && 'border border-border bg-background hover:bg-muted',
        variant === 'ghost' && 'hover:bg-muted',
        variant === 'destructive' && 'bg-destructive text-white hover:bg-destructive/90',
        size === 'sm' && 'h-8 px-3 text-xs',
        size === 'md' && 'h-9 px-4 text-sm',
        size === 'lg' && 'h-10 px-6 text-sm',
        className
      )}
      {...props}
    />
  );
}
