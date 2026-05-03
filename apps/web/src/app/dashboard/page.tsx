'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { MobileNav } from '@/components/MobileNav';
import { AuthGuard } from '@/components/AuthGuard';
import { useStore } from '@/lib/store';
import { apiClient } from '@/lib/api-client';
import { IconSignOut } from '@/components/icons';
import { ConfirmDialog } from '@/components/ConfirmDialog';

interface LeaderboardEntry {
  rank: number;
  score: number;
  user: { id: string; username: string; displayName: string | null; level: number };
}

const QUICK_ACTIONS = [
  { label: 'Destinations', desc: 'Browse tourism spots', href: '/destinations', icon: '🗺️' },
  { label: 'Quests',       desc: 'View active missions', href: '/quests',        icon: '📍' },
  { label: 'Checkpoints',  desc: 'Generate QR tokens',  href: '/checkpoints',   icon: '🔲' },
  { label: 'Leaderboard',  desc: 'Top explorers',       href: '/leaderboard',   icon: '🏆' },
  { label: 'Passports',    desc: 'Digital stamp books',  href: '/passports',     icon: '📖' },
  { label: 'Rewards',      desc: 'Manage vouchers',      href: '/rewards',       icon: '🎁' },
];

const MEDALS = ['🥇', '🥈', '🥉'];

function AnimatedNumber({ value }: { value: number }) {
  const [display, setDisplay] = useState(0);
  const rafRef   = useRef<number>(0);

  useEffect(() => {
    cancelAnimationFrame(rafRef.current);
    if (value === 0) { setDisplay(0); return; }
    const start     = performance.now();
    const duration  = 700;
    const from      = 0;
    const tick = (now: number) => {
      const p    = Math.min((now - start) / duration, 1);
      const ease = 1 - Math.pow(1 - p, 3); // ease-out cubic
      setDisplay(Math.round(from + (value - from) * ease));
      if (p < 1) rafRef.current = requestAnimationFrame(tick);
    };
    rafRef.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafRef.current);
  }, [value]);

  return <>{display.toLocaleString()}</>;
}

function RankBadge({ index, rank }: { index: number; rank: number }) {
  if (index < 3) {
    return (
      <div className="w-8 h-8 rounded-full bg-trail-peach flex items-center justify-center text-lg shrink-0">
        {MEDALS[index]}
      </div>
    );
  }
  return (
    <div className="w-8 h-8 rounded-full bg-trail-peach flex items-center justify-center text-xs font-bold shrink-0 text-gray-500">
      #{rank}
    </div>
  );
}

const API_ORIGIN = (process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000/v1').replace(/\/v1$/, '');
function resolveAvatarUrl(url: string | null | undefined): string {
  if (!url) return '';
  if (url.startsWith('http')) return url;
  return `${API_ORIGIN}${url}`;
}

export default function DashboardPage() {
  const { user, destinations, quests, setDestinations, setQuests, logout } = useStore();
  const router = useRouter();
  const [leaderboard, setLeaderboard]   = useState<LeaderboardEntry[]>([]);
  const [confirmOpen, setConfirmOpen]   = useState(false);
  // Show cached store data immediately; only block on loading when store is empty.
  const [loading, setLoading]   = useState(destinations.length === 0 && quests.length === 0);
  const [loadError, setLoadError] = useState(false);
  // Guard against React 18 Strict Mode double-invoking effects (prevents a race
  // where the second invocation resets loading before the first resolves).
  const fetchedRef = useRef(false);

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  const runFetch = () => {
    setLoadError(false);
    setLoading(true);
    Promise.allSettled([
      apiClient.get('/destinations'),
      apiClient.get('/quests'),
      apiClient.get('/leaderboards/global?limit=5'),
    ]).then(([d, q, lb]) => {
      if (d.status === 'fulfilled') setDestinations(d.value.data ?? []);
      if (q.status === 'fulfilled') setQuests(q.value.data ?? []);
      if (lb.status === 'fulfilled') setLeaderboard(lb.value.data ?? []);
      // Only error banner for core endpoints; leaderboard failure is non-critical
      if (d.status === 'rejected' || q.status === 'rejected') setLoadError(true);
      setLoading(false);
    }).catch(() => setLoading(false));
  };

  useEffect(() => {
    if (fetchedRef.current) return;
    fetchedRef.current = true;
    runFetch();
  }, []);

  const totalXp = leaderboard.reduce((s, e) => s + e.score, 0);
  const xpPct   = user
    ? Math.min(100, Math.round((user.xpTotal / Math.max(user.xpForNextLevel, 1)) * 100))
    : 0;
  const initials = user?.username?.[0]?.toUpperCase() ?? '?';
  const photoUrl = resolveAvatarUrl(user?.avatarUrl);

  const STAT_CARDS = [
    { label: 'Destinations',  count: destinations.length, icon: '🗺️', sub: 'Tourism spots',   href: '/destinations' },
    { label: 'Active Quests', count: quests.length,       icon: '📍', sub: 'Missions',        href: '/quests' },
    { label: 'Top Explorers', count: leaderboard.length,  icon: '👥', sub: 'On leaderboard',  href: '/leaderboard' },
    { label: 'Total XP',      count: totalXp,             icon: '⭐', sub: 'Across platform', href: '/analytics' },
  ];

  return (
    <AuthGuard>
      <div className="flex bg-trail-cream min-h-screen">
        <Sidebar />

        <main className="flex-1 min-w-0 flex flex-col">

          {/* ── Sticky header ── */}
          <div className="bg-white border-b border-gray-100 px-4 md:px-8 py-3 md:py-5 sticky top-0 z-40">
            <div className="flex items-center justify-between gap-3">
              <div className="min-w-0">
                <h1 className="text-base md:text-2xl font-bold text-trail-brown truncate">
                  Hey, {user?.displayName ?? user?.username ?? 'Explorer'}
                </h1>
                <p className="text-xs md:text-sm text-gray-400 mt-0.5 hidden sm:block">
                  Here's what's happening on Lakbai today
                </p>
              </div>

              <div className="flex items-center gap-2 shrink-0">
                {/* Sign out — mobile only; desktop uses Sidebar */}
                <button
                  onClick={() => setConfirmOpen(true)}
                  aria-label="Sign out"
                  className="md:hidden flex items-center justify-center w-9 h-9 rounded-xl
                             text-gray-400 hover:text-trail-brown hover:bg-gray-100
                             active:scale-95 transition-all"
                >
                  <IconSignOut size={18} />
                </button>

                {photoUrl ? (
                  <Link
                    href="/profile"
                    aria-label="View profile"
                    className="w-10 h-10 rounded-xl overflow-hidden
                               transition-opacity active:scale-95 hover:opacity-90"
                  >
                    <img src={photoUrl} alt="Avatar" className="w-full h-full object-cover object-center" />
                  </Link>
                ) : (
                  <Link
                    href="/profile"
                    aria-label="View profile"
                    className="flex items-center gap-2 font-semibold
                               bg-trail-orange text-white rounded-xl
                               transition-colors active:scale-95 hover:bg-trail-orange-dark
                               px-3 py-2 md:px-4 md:py-2 text-sm"
                  >
                    <span className="w-8 h-8 rounded-full overflow-hidden bg-white/20 flex items-center justify-center
                                     text-xs font-bold shrink-0">
                      {initials}
                    </span>
                    <span className="hidden sm:inline">View Profile</span>
                  </Link>
                )}
              </div>
            </div>
          </div>

          {/* ── Scrollable body ── */}
          <div className="flex-1 overflow-y-auto">
            <div className="px-4 md:px-8 py-4 md:py-6 pb-24 md:pb-6 space-y-4 md:space-y-6">

              {/* ── XP level card ── */}
              {user && (
                <div className="bg-trail-brown rounded-2xl p-4 md:p-6 text-white relative overflow-hidden">
                  <div className="absolute top-0 right-0 w-32 h-32 bg-trail-orange opacity-10
                                  rounded-full -translate-y-8 translate-x-8" />
                  <div className="relative">
                    <div className="flex items-center justify-between mb-3 md:mb-4">
                      <div>
                        <p className="text-trail-peach text-xs font-medium">Your Progress</p>
                        <h2 className="text-2xl md:text-3xl font-bold text-white mt-0.5">
                          Level {user.level}
                        </h2>
                      </div>
                      <div className="text-right">
                        <p className="text-trail-peach text-xs">Total XP</p>
                        <p className="text-xl md:text-2xl font-bold text-trail-orange">
                          {user.xpTotal.toLocaleString()}
                        </p>
                      </div>
                    </div>
                    <div className="space-y-1.5">
                      <div className="flex justify-between text-xs text-trail-peach">
                        <span>{user.xpTotal.toLocaleString()} XP</span>
                        <span>{user.xpForNextLevel.toLocaleString()} XP to Lv {user.level + 1}</span>
                      </div>
                      <div className="w-full bg-trail-brown-mid rounded-full h-2">
                        <div
                          className="bg-trail-orange h-2 rounded-full transition-all duration-700"
                          style={{ width: `${xpPct}%` }}
                        />
                      </div>
                      <p className="text-xs text-trail-peach opacity-60">{xpPct}% to next level</p>
                    </div>
                  </div>
                </div>
              )}

              {/* ── API error banner ── */}
              {loadError && (
                <div className="bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm text-red-600 flex items-center justify-between gap-3">
                  <span>Some data failed to load.</span>
                  <button
                    onClick={runFetch}
                    className="shrink-0 text-xs font-semibold underline underline-offset-2 hover:no-underline"
                  >
                    Retry
                  </button>
                </div>
              )}

              {/* ── Stat cards — 2-col on mobile, 4-col on lg ── */}
              <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
                {STAT_CARDS.map((s) => (
                  <Link
                    key={s.label}
                    href={s.href}
                    className="bg-white rounded-xl p-3 md:p-5 shadow-sm border border-gray-100
                               hover:shadow-md hover:border-trail-orange transition-all active:scale-95"
                  >
                    <div className="flex items-start justify-between">
                      <div className="min-w-0">
                        <p className="text-[10px] md:text-xs font-semibold text-gray-400 uppercase tracking-wide leading-tight">
                          {s.label}
                        </p>
                        <p className="text-2xl md:text-3xl font-bold text-trail-brown mt-1">
                          {loading ? '—' : <AnimatedNumber value={s.count} />}
                        </p>
                        <p className="text-[10px] md:text-xs text-gray-400 mt-0.5">{s.sub}</p>
                      </div>
                      <span className="text-2xl shrink-0 mt-0.5">{s.icon}</span>
                    </div>
                  </Link>
                ))}
              </div>

              {/* ── Bottom section: Leaderboard + Quick Access ── */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-6">

                {/* Top Explorers */}
                <div className="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-4 md:p-6">
                  <div className="flex items-center justify-between mb-4">
                    <h2 className="font-bold text-trail-brown text-base md:text-lg flex items-center gap-2">
                      🏆 Top Explorers
                    </h2>
                    <Link
                      href="/leaderboard"
                      className="text-xs text-trail-orange hover:text-trail-orange-dark font-semibold"
                    >
                      View all →
                    </Link>
                  </div>

                  {loading ? (
                    <div className="space-y-3">
                      {[1, 2, 3].map((i) => (
                        <div key={i} className="h-12 bg-trail-cream rounded-xl animate-pulse" />
                      ))}
                    </div>
                  ) : leaderboard.length === 0 ? (
                    <div className="text-center py-8 text-gray-400">
                      <p className="text-4xl mb-2">🏅</p>
                      <p className="text-sm font-medium text-trail-brown mb-1">No activity yet</p>
                      <p className="text-xs">Appears after users complete quests.</p>
                    </div>
                  ) : (
                    <div className="divide-y divide-gray-50">
                      {leaderboard.map((e, i) => (
                        <div
                          key={e.user.id}
                          className="flex items-center gap-3 py-3 first:pt-0 last:pb-0"
                        >
                          <RankBadge index={i} rank={e.rank} />
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-semibold text-trail-brown truncate">
                              {e.user.displayName ?? e.user.username}
                            </p>
                            <p className="text-xs text-gray-400">Level {e.user.level}</p>
                          </div>
                          <span className="text-sm font-bold text-trail-orange shrink-0">
                            {e.score.toLocaleString()} XP
                          </span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Quick Access */}
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 md:p-6">
                  <h2 className="font-bold text-trail-brown text-base md:text-lg mb-3 md:mb-4 flex items-center gap-2">
                    ⚡ Quick Access
                  </h2>

                  {/* Mobile: 3-col icon grid */}
                  <div className="grid grid-cols-3 gap-2 md:hidden">
                    {QUICK_ACTIONS.map((a) => (
                      <Link
                        key={a.label}
                        href={a.href}
                        className="flex flex-col items-center gap-1.5 p-3 rounded-xl bg-trail-cream
                                   hover:bg-trail-peach transition-colors active:scale-95 text-center"
                      >
                        <span className="text-2xl">{a.icon}</span>
                        <span className="text-[10px] font-semibold text-trail-brown leading-tight">
                          {a.label}
                        </span>
                      </Link>
                    ))}
                  </div>

                  {/* Desktop: list */}
                  <div className="hidden md:block space-y-1">
                    {QUICK_ACTIONS.map((a) => (
                      <Link
                        key={a.label}
                        href={a.href}
                        className="flex items-center gap-3 px-3 py-2.5 rounded-xl
                                   hover:bg-trail-cream transition-colors group"
                      >
                        <span className="text-xl shrink-0">{a.icon}</span>
                        <div className="min-w-0">
                          <p className="text-sm font-semibold text-trail-brown leading-tight">{a.label}</p>
                          <p className="text-xs text-gray-400">{a.desc}</p>
                        </div>
                        <span className="ml-auto text-trail-orange text-sm opacity-0 group-hover:opacity-100 transition-opacity">
                          →
                        </span>
                      </Link>
                    ))}
                  </div>
                </div>

              </div>
            </div>
          </div>

          <MobileNav />

          <ConfirmDialog
            open={confirmOpen}
            title="Sign out?"
            message="You'll need to sign in again to access your dashboard."
            confirmLabel="Sign Out"
            cancelLabel="Cancel"
            onConfirm={handleLogout}
            onCancel={() => setConfirmOpen(false)}
          />
        </main>
      </div>
    </AuthGuard>
  );
}
