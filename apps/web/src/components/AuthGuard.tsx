'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useStore } from '@/lib/store';
import { getCurrentUser } from '@/lib/auth';

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, setUser } = useStore();
  const router = useRouter();
  // null = SSR / first paint (avoid hydration mismatch), false = no token, true = token present
  const [hasToken, setHasToken] = useState<boolean | null>(null);

  useEffect(() => {
    const token = localStorage.getItem('access_token');
    if (!token) {
      setHasToken(false);
      router.replace('/login');
      return;
    }
    // Token found — show children immediately, verify in background
    setHasToken(true);
    if (isAuthenticated) return;
    getCurrentUser()
      .then(setUser)
      .catch(() => {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        router.replace('/login');
      });
  }, []);

  // SSR / first render: return null to avoid hydration mismatch
  if (hasToken === null || hasToken === false) return null;

  return <>{children}</>;
}
