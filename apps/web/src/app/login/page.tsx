'use client';

import { useState } from 'react';
import Image from 'next/image';
import { useAuthStore } from '@/stores/auth-store';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/Button';
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

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-[rgb(var(--background))] via-stone-50/80 to-accent/20 p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-10">
          <h1 className="sr-only">Be Electric</h1>
          <div className="flex justify-center mb-4">
            <Image
              src={beElectricLogo}
              alt="Be Electric"
              className="h-14 w-auto object-contain"
              priority
            />
          </div>
          <p className="text-muted-foreground mt-1 text-sm">QAuto CMMS</p>
        </div>
        <div className="rounded-xl border border-border bg-card p-8 shadow-card">
          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Email
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@company.com"
                className={cn(
                  'w-full rounded-lg border border-input bg-background px-4 py-2.5 text-sm',
                  'placeholder:text-muted-foreground',
                  'focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary',
                  'transition-colors'
                )}
                required
              />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Password
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className={cn(
                  'w-full rounded-lg border border-input bg-background px-4 py-2.5 text-sm',
                  'placeholder:text-muted-foreground',
                  'focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary',
                  'transition-colors'
                )}
                required
              />
            </div>
            {error && (
              <p className="text-sm text-destructive">{error}</p>
            )}
            <Button
              type="submit"
              disabled={loading}
              className="w-full"
            >
              {loading ? 'Signing in...' : 'Sign In'}
            </Button>
          </form>
        </div>
        <p className="text-xs text-muted-foreground text-center mt-6">
          Demo: admin@qauto.com / demo123
        </p>
      </div>
    </div>
  );
}
