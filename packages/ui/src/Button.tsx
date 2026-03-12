import React from 'react';
import { tokens } from './design-tokens';

type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  fullWidth?: boolean;
  children: React.ReactNode;
}

export function Button({
  variant = 'primary',
  fullWidth,
  children,
  style,
  ...props
}: ButtonProps) {
  const base: React.CSSProperties = {
    fontFamily: tokens.font.sans,
    fontWeight: tokens.font.weights.semibold,
    fontSize: tokens.font.sizes.body,
    padding: `${tokens.spacing.s}px ${tokens.spacing.xl}px`,
    borderRadius: tokens.radius.button,
    cursor: props.disabled ? 'not-allowed' : 'pointer',
    border: 'none',
    width: fullWidth ? '100%' : undefined,
    opacity: props.disabled ? 0.6 : 1,
  };
  const variants: Record<ButtonVariant, React.CSSProperties> = {
    primary: { background: tokens.colors.accentGreen, color: '#fff' },
    secondary: { background: tokens.colors.accentBlue, color: '#fff' },
    outline: {
      background: 'transparent',
      color: tokens.colors.accentGreen,
      border: `1px solid ${tokens.colors.accentGreen}`,
    },
    ghost: { background: 'transparent', color: tokens.colors.darkText },
    destructive: { background: tokens.colors.accentRed, color: '#fff' },
  };
  return (
    <button style={{ ...base, ...variants[variant], ...style }} {...props}>
      {children}
    </button>
  );
}
