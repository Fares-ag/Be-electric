'use client';

import { useEffect, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useAuthStore } from '@/stores/auth-store';
import { useRealtimeSubscriptions } from '@/hooks/useRealtime';
import { Inter, Plus_Jakarta_Sans } from 'next/font/google';
import './globals.css';

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-sans',
  display: 'swap',
  preload: true,
});
const plusJakarta = Plus_Jakarta_Sans({
  subsets: ['latin'],
  variable: '--font-display',
  display: 'swap',
  preload: true,
});

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000, // 1 min: avoid refetch on every nav
      gcTime: 5 * 60 * 1000, // 5 min (formerly cacheTime)
    },
  },
});

function RealtimeProvider({ children }: { children: React.ReactNode }) {
  useRealtimeSubscriptions();
  return <>{children}</>;
}

/** Renders children first, then mounts RealtimeProvider after first paint to keep initial load fast. */
function DeferredRealtime({ children }: { children: React.ReactNode }) {
  const [mounted, setMounted] = useState(false);
  useEffect(() => {
    const t = requestAnimationFrame(() => {
      setMounted(true);
    });
    return () => cancelAnimationFrame(t);
  }, []);
  if (!mounted) return <>{children}</>;
  return <RealtimeProvider>{children}</RealtimeProvider>;
}

function AuthGuard({ children }: { children: React.ReactNode }) {
  const { user, loading, init } = useAuthStore();
  const pathname = usePathname();
  const router = useRouter();
  const isLogin = pathname === '/login';

  useEffect(() => {
    init();
  }, [init]);

  useEffect(() => {
    if (loading) return;
    if (!user && !isLogin) {
      router.replace('/login');
      return;
    }
    if (user && isLogin) {
      const isAdmin = user.role === 'admin' || user.role === 'manager';
      router.replace(isAdmin ? '/dashboard' : '/my-requests');
    }
  }, [user, loading, isLogin, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-3">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
          <p className="text-sm text-muted-foreground">Loading...</p>
        </div>
      </div>
    );
  }
  if (!user && !isLogin) return null;
  if (user && isLogin) return null;
  return <DeferredRealtime>{children}</DeferredRealtime>;
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${inter.variable} ${plusJakarta.variable}`}>
      <body className="font-sans">
        <QueryClientProvider client={queryClient}>
          <AuthGuard>{children}</AuthGuard>
        </QueryClientProvider>
      </body>
    </html>
  );
}
