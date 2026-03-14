'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname, useRouter } from 'next/navigation';
import { useQueryClient } from '@tanstack/react-query';
import { useAuthStore } from '@/stores/auth-store';
import { prefetchRoute } from '@/lib/prefetch-routes';
import {
  LayoutDashboard,
  Wrench,
  ClipboardList,
  Package,
  Users,
  Building2,
  Boxes,
  ClipboardCheck,
  ShoppingCart,
  BarChart3,
  FileText,
  Settings,
  Bell,
  PlusCircle,
  BarChart2,
  LogOut,
  Menu,
  X,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import beElectricLogo from '@/app/(app)/assets/beElectricLogo.png';

const adminNav = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/work-orders', label: 'Work Orders', icon: Wrench },
  { href: '/pm-tasks', label: 'PM Tasks', icon: ClipboardList },
  { href: '/assets', label: 'Chargers', icon: Package },
  { href: '/users', label: 'Users', icon: Users },
  { href: '/companies', label: 'Companies', icon: Building2 },
  { href: '/inventory', label: 'Inventory', icon: Boxes },
  { href: '/parts-requests', label: 'Parts Requests', icon: ClipboardCheck },
  { href: '/purchase-orders', label: 'Purchase Orders', icon: ShoppingCart },
  { href: '/analytics', label: 'Analytics', icon: BarChart3 },
  { href: '/reports', label: 'Reports', icon: FileText },
  { href: '/settings', label: 'Settings', icon: Settings },
  { href: '/notifications', label: 'Notifications', icon: Bell },
];

const requestorNav = [
  { href: '/request', label: 'Request Maintenance', icon: PlusCircle },
  { href: '/my-requests', label: 'My Requests', icon: ClipboardList },
  { href: '/requestor-analytics', label: 'Analytics', icon: BarChart2 },
  { href: '/notification-settings', label: 'Notification Settings', icon: Settings },
  { href: '/notifications', label: 'Notifications', icon: Bell },
];

function NavLinks({
  nav,
  pathname,
  onPrefetch,
  onLinkClick,
}: {
  nav: typeof adminNav;
  pathname: string;
  onPrefetch: (href: string) => void;
  onLinkClick?: () => void;
}) {
  return (
    <>
      {nav.map(({ href, label, icon: Icon }) => {
        const isActive = pathname === href;
        return (
          <Link
            key={href}
            href={href}
            prefetch
            onClick={onLinkClick}
            onMouseEnter={() => onPrefetch(href)}
            onTouchStart={() => onPrefetch(href)}
            className={cn(
              'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-200 min-h-[44px]',
              isActive
                ? 'bg-primary text-primary-foreground shadow-button-primary'
                : 'text-muted-foreground hover:bg-muted hover:text-foreground'
            )}
          >
            <Icon className="h-4 w-4 shrink-0" />
            {label}
          </Link>
        );
      })}
    </>
  );
}

export function RoleBasedLayout({ children }: { children: React.ReactNode }) {
  const user = useAuthStore((s) => s.user);
  const signOut = useAuthStore((s) => s.signOut);
  const pathname = usePathname();
  const router = useRouter();
  const queryClient = useQueryClient();
  const isAdmin = user?.role === 'admin' || user?.role === 'manager';
  const nav = isAdmin ? adminNav : requestorNav;
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Close mobile menu on route change
  useEffect(() => {
    setMobileMenuOpen(false);
  }, [pathname]);

  // Lock body scroll when mobile menu is open
  useEffect(() => {
    if (mobileMenuOpen) document.body.style.overflow = 'hidden';
    else document.body.style.overflow = '';
    return () => {
      document.body.style.overflow = '';
    };
  }, [mobileMenuOpen]);

  const handleNavPrefetch = (href: string) => {
    router.prefetch(href);
    prefetchRoute(queryClient, href);
  };

  const brand = (
      <div className="flex h-16 items-center gap-3 border-b border-border px-5 shrink-0">
      <Image
        src={beElectricLogo}
        alt="Be Electric"
        className="h-9 w-auto object-contain"
        priority
      />
    </div>
  );

  const footerBlock = (
    <div className="border-t border-border bg-muted/30 p-4 shrink-0">
      <p className="truncate text-xs font-medium text-foreground">{user?.email}</p>
      <p className="truncate text-xs text-muted-foreground capitalize">{user?.role}</p>
      <button
        type="button"
        onClick={() => signOut()}
        className={cn(
          'mt-3 flex w-full items-center gap-2 rounded-lg px-3 py-2.5 text-sm font-medium min-h-[44px]',
          'text-muted-foreground hover:bg-muted hover:text-foreground',
          'transition-colors duration-200'
        )}
      >
        <LogOut className="h-4 w-4" />
        Sign Out
      </button>
    </div>
  );

  return (
    <div className="flex min-h-screen bg-background">
      {/* Desktop sidebar: hidden on mobile */}
      <aside className="hidden md:flex w-64 flex-col border-r border-border bg-card shadow-soft">
        {brand}
        <nav className="flex-1 space-y-0.5 overflow-y-auto p-3">
          <NavLinks nav={nav} pathname={pathname} onPrefetch={handleNavPrefetch} />
        </nav>
        {footerBlock}
      </aside>

      {/* Mobile header: logo centered, menu right */}
      <div className="fixed top-0 left-0 right-0 z-40 grid h-14 grid-cols-3 items-center border-b border-border bg-card px-4 md:hidden">
        <div className="w-10" aria-hidden />
        <div className="flex justify-center">
          <Image
            src={beElectricLogo}
            alt="Be Electric"
            className="h-8 w-auto object-contain"
            priority
          />
        </div>
        <div className="flex justify-end">
          <button
            type="button"
            aria-label="Open menu"
            onClick={() => setMobileMenuOpen(true)}
            className="flex h-10 w-10 items-center justify-center rounded-lg text-foreground hover:bg-muted transition-colors"
          >
            <Menu className="h-6 w-6" />
          </button>
        </div>
      </div>

      {/* Mobile menu overlay + drawer */}
      <div
        className={cn(
          'fixed inset-0 z-50 md:hidden transition-opacity duration-200',
          mobileMenuOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'
        )}
        aria-hidden={!mobileMenuOpen}
      >
        <button
          type="button"
          aria-label="Close menu"
          className="absolute inset-0 bg-black/50 backdrop-blur-sm"
          onClick={() => setMobileMenuOpen(false)}
        />
        <aside
          className={cn(
            'absolute top-0 left-0 bottom-0 w-[min(280px,85vw)] flex flex-col bg-card border-r border-border shadow-xl transition-transform duration-200 ease-out',
            mobileMenuOpen ? 'translate-x-0' : '-translate-x-full'
          )}
        >
          <div className="flex h-14 items-center justify-between px-4 border-b border-border">
            <span className="font-display text-base font-semibold text-foreground">Menu</span>
            <button
              type="button"
              aria-label="Close menu"
              onClick={() => setMobileMenuOpen(false)}
              className="flex h-10 w-10 items-center justify-center rounded-lg text-foreground hover:bg-muted"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
          <nav className="flex-1 space-y-0.5 overflow-y-auto p-3">
            <NavLinks
              nav={nav}
              pathname={pathname}
              onPrefetch={handleNavPrefetch}
              onLinkClick={() => setMobileMenuOpen(false)}
            />
          </nav>
          {footerBlock}
        </aside>
      </div>

      <main className="flex-1 overflow-auto min-h-screen">
        <div className="container max-w-7xl px-4 pt-14 pb-8 md:px-6 md:pt-8 md:pb-8">{children}</div>
      </main>
    </div>
  );
}
