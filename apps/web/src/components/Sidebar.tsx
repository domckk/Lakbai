'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useStore } from '@/lib/store';
import {
  IconDashboard, IconDestinations, IconQuests, IconCheckpoints,
  IconLeaderboard, IconPassports, IconRewards, IconAnalytics,
  IconSignOut,
} from '@/components/icons';
import { ConfirmDialog } from '@/components/ConfirmDialog';

const NAV_ITEMS = [
  { label: 'Dashboard',    href: '/dashboard',    Icon: IconDashboard    },
  { label: 'Destinations', href: '/destinations', Icon: IconDestinations },
  { label: 'Quests',       href: '/quests',       Icon: IconQuests       },
  { label: 'Checkpoints',  href: '/checkpoints',  Icon: IconCheckpoints  },
  { label: 'Leaderboard',  href: '/leaderboard',  Icon: IconLeaderboard  },
  { label: 'Passports',    href: '/passports',    Icon: IconPassports    },
  { label: 'Rewards',      href: '/rewards',      Icon: IconRewards      },
  { label: 'Analytics',    href: '/analytics',    Icon: IconAnalytics    },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useStore();

  const [confirmOpen, setConfirmOpen] = useState(false);

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  const xpPercent = user
    ? Math.min(100, Math.round((user.xpTotal / Math.max(user.xpForNextLevel, 1)) * 100))
    : 0;

  return (
    <aside className="w-64 bg-trail-brown text-white flex-col hidden md:flex sticky top-0 h-screen overflow-y-auto shrink-0">
      {/* Logo */}
      <div className="px-6 pt-6 pb-4">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/images/logo.png" alt="Lakbai" width={110} className="block" />
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-2 space-y-0.5">
        {NAV_ITEMS.map(({ label, href, Icon }) => {
          const active = pathname === href || pathname.startsWith(href + '/');
          return (
            <Link
              key={label}
              href={href}
              className={`flex items-center gap-3 px-3 py-2 rounded-lg transition-all text-sm font-medium ${
                active
                  ? 'bg-trail-orange text-white shadow-sm'
                  : 'text-trail-peach hover:bg-trail-brown-mid hover:text-white'
              }`}
            >
              <Icon size={17} className="shrink-0" />
              <span>{label}</span>
              {active && <span className="ml-auto w-1.5 h-1.5 rounded-full bg-white opacity-80" />}
            </Link>
          );
        })}
      </nav>

      {/* User section */}
      <div className="px-3 pb-4 pt-2 border-t border-trail-brown-mid mt-2">
        {/* XP bar */}
        {user && (
          <div className="px-3 py-3 mb-2 rounded-lg bg-trail-brown-mid">
            <div className="flex justify-between items-center mb-1.5">
              <span className="text-xs font-semibold text-trail-peach">
                Lv.{user.level}
              </span>
              <span className="text-xs text-trail-peach opacity-60">
                {user.xpTotal.toLocaleString()} / {user.xpForNextLevel.toLocaleString()} XP
              </span>
            </div>
            <div className="w-full bg-trail-brown rounded-full h-1.5">
              <div
                className="bg-trail-orange h-1.5 rounded-full transition-all duration-500"
                style={{ width: `${xpPercent}%` }}
              />
            </div>
          </div>
        )}

        {/* Profile link */}
        <Link
          href="/profile"
          className={`flex items-center gap-3 px-3 py-2 rounded-lg transition-all mb-1 ${
            pathname === '/profile'
              ? 'bg-trail-orange text-white'
              : 'hover:bg-trail-brown-mid text-trail-peach hover:text-white'
          }`}
        >
          <div className="w-7 h-7 rounded-full bg-trail-orange flex items-center justify-center text-white font-bold text-xs shrink-0">
            {user?.username?.[0]?.toUpperCase() ?? '?'}
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-xs font-semibold text-white truncate leading-tight">
              {user?.displayName ?? user?.username}
            </p>
            <p className="text-xs text-trail-peach opacity-60 truncate">{user?.email}</p>
          </div>
        </Link>

        <button
          onClick={() => setConfirmOpen(true)}
          className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-trail-peach hover:bg-trail-brown-mid hover:text-white transition-all text-sm"
        >
          <IconSignOut size={17} className="shrink-0" />
          <span>Sign Out</span>
        </button>

        <ConfirmDialog
          open={confirmOpen}
          title="Sign out?"
          message="You'll need to sign in again to access your dashboard."
          confirmLabel="Sign Out"
          cancelLabel="Cancel"
          onConfirm={handleLogout}
          onCancel={() => setConfirmOpen(false)}
        />
      </div>
    </aside>
  );
}
