import React from 'react';
import { tokens } from './design-tokens';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

export function Input({ label, error, style, ...props }: InputProps) {
  return (
    <div style={{ marginBottom: tokens.spacing.m }}>
      {label && (
        <label
          style={{
            display: 'block',
            fontFamily: tokens.font.sans,
            fontSize: tokens.font.sizes.secondary,
            color: tokens.colors.darkText,
            marginBottom: tokens.spacing.xs,
          }}
        >
          {label}
        </label>
      )}
      <input
        style={{
          width: '100%',
          padding: `${tokens.spacing.s}px ${tokens.spacing.m}`,
          borderRadius: tokens.radius.input,
          border: `1px solid ${error ? tokens.colors.accentRed : tokens.colors.border}`,
          fontFamily: tokens.font.sans,
          fontSize: tokens.font.sizes.body,
          color: tokens.colors.darkText,
          outline: 'none',
          boxSizing: 'border-box',
          ...style,
        }}
        {...props}
      />
      {error && (
        <span
          style={{
            fontSize: tokens.font.sizes.small,
            color: tokens.colors.accentRed,
            marginTop: tokens.spacing.xs,
            display: 'block',
          }}
        >
          {error}
        </span>
      )}
    </div>
  );
}
