'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/stores/auth-store';

export default function Home() {
  const { user, loading } = useAuthStore();
  const router = useRouter();

  useEffect(() => {
    if (loading) return;
    if (!user) {
      router.replace('/login');
      return;
    }
    const isAdmin = user.role === 'admin' || user.role === 'manager';
    router.replace(isAdmin ? '/dashboard' : '/my-requests');
  }, [user, loading, router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#F5F5F5]">
      <div className="text-[#757575]">Redirecting...</div>
    </div>
  );
}
