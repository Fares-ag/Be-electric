'use client';

import { useState } from 'react';
import Image from 'next/image';
import { useAuthStore } from '@/stores/auth-store';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/Button';
import { Mail, Lock, AlertCircle } from 'lucide-react';
import beElectricLogo from '../(app)/assets/beElectricLogo.png';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const signIn = useAuthStore((s) => s.signIn);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    const { error: err } = await signIn(email, password);
    setLoading(false);
    if (err) setError(err.message ?? 'Login failed');
  }

  const inputBase = cn(
    'w-full rounded-lg border border-input bg-background pl-10 pr-4 py-3 text-sm',
    'placeholder:text-muted-foreground',
    'focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary',
    'transition-colors'
  );

  return (
    <div className="min-h-screen flex items-center justify-center p-4 sm:p-6">
      {/* Background: gradient with subtle pattern */}
      <div
        className="fixed inset-0 -z-10 bg-gradient-to-br from-[rgb(var(--background))] via-stone-50 to-[rgb(var(--accent))]/30"
        aria-hidden
      />
      <div className="absolute inset-0 -z-10 opacity-[0.03] bg-[linear-gradient(rgba(5,46,22,0.5)_1px,transparent_1px),linear-gradient(90deg,rgba(5,46,22,0.5)_1px,transparent_1px)] bg-[size:32px_32px]" />

      <div className="w-full max-w-md">
        {/* Logo & tagline */}
        <div className="text-center mb-10">
          <h1 className="sr-only">Be Electric</h1>
          <div className="flex justify-center mb-4">
            <Image
              src={beElectricLogo}
              alt="Be Electric"
              className="h-16 w-auto object-contain sm:h-[4.5rem]"
              priority
            />
          </div>
          <p className="text-sm text-muted-foreground">
            CMMS for maintenance & work orders
          </p>
        </div>

        {/* Card */}
        <div className="rounded-2xl border border-border bg-card/95 backdrop-blur-sm p-8 shadow-lg shadow-black/5">
          <h2 className="text-lg font-semibold text-foreground mb-6">
            Sign in to your account
          </h2>
          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label htmlFor="email" className="mb-1.5 block text-sm font-medium text-foreground">
                Email
              </label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@company.com"
                  autoComplete="email"
                  className={inputBase}
                  required
                />
              </div>
            </div>
            <div>
              <label htmlFor="password" className="mb-1.5 block text-sm font-medium text-foreground">
                Password
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                  placeholder="••••••••"
                  className={inputBase}
                  required
                />
              </div>
            </div>
            {error && (
              <div
                role="alert"
                className="flex items-center gap-2 rounded-lg bg-destructive/10 px-3 py-2.5 text-sm text-destructive"
              >
                <AlertCircle className="h-4 w-4 shrink-0" />
                <span>{error}</span>
              </div>
            )}
            <Button
              type="submit"
              disabled={loading}
              className="w-full py-3"
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" />
                  Signing in...
                </span>
              ) : (
                'Sign In'
              )}
            </Button>
          </form>
        </div>

        <p className="mt-6 text-center text-xs text-muted-foreground">
          Forgot your password? Contact your administrator.
        </p>
      </div>
    </div>
  );
}
