'use client';

import { useEffect, useState } from 'react';
import { Sidebar } from '@/components/Sidebar';
import { MobileNav } from '@/components/MobileNav';
import { PageHeader } from '@/components/PageHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { useStore } from '@/lib/store';
import { apiClient } from '@/lib/api-client';

interface LeaderboardEntry {
  rank: number;
  score: number;
  user: { id: string; username: string; displayName: string | null; level: number };
}

const DIFF_LABEL: Record<number, string> = { 1: 'Very Easy', 2: 'Easy', 3: 'Medium', 4: 'Hard', 5: 'Extreme' };
const DIFF_COLOR: Record<number, string> = {
  1: 'bg-green-100 text-green-700', 2: 'bg-green-100 text-green-700',
  3: 'bg-yellow-100 text-yellow-800', 4: 'bg-orange-100 text-orange-700',
  5: 'bg-red-100 text-red-700',
};
const TYPE_ICON: Record<string, string> = {
  landmark: '🏛️', food: '🍜', cultural: '🎭',
  adventure: '⛰️', shopping: '🛍️', heritage: '🏺', nature: '🌿', route: '🛤️',
};
const TYPE_COLOR: Record<string, string> = {
  landmark: 'bg-amber-100 text-amber-800',
  food: 'bg-orange-100 text-orange-700',
  cultural: 'bg-purple-100 text-purple-700',
  adventure: 'bg-teal-100 text-teal-700',
  heritage: 'bg-stone-100 text-stone-700',
  nature: 'bg-green-100 text-green-700',
  route: 'bg-blue-100 text-blue-700',
  shopping: 'bg-pink-100 text-pink-700',
};
const MEDAL: Record<number, string> = { 1: '🥇', 2: '🥈', 3: '🥉' };

export default function AnalyticsPage() {
  const { destinations, quests, setDestinations, setQuests } = useStore();
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [loading, setLoading]         = useState(true);
  const [selectedDestId, setSelectedDestId] = useState('');

  useEffect(() => {
    Promise.allSettled([
      apiClient.get('/destinations'),
      apiClient.get('/quests'),
      apiClient.get('/leaderboards/global?limit=10'),
    ]).then(([dr, qr, lr]) => {
      if (dr.status === 'fulfilled') setDestinations(dr.value.data ?? []);
      if (qr.status === 'fulfilled') setQuests(qr.value.data ?? []);
      if (lr.status === 'fulfilled') setLeaderboard(lr.value.data ?? []);
      setLoading(false);
    });
  }, []);

  const filteredQuests = selectedDestId
    ? quests.filter((q) => q.destinationId === selectedDestId)
    : quests;

  const maxScore   = leaderboard[0]?.score ?? 1;
  const avgXp      = leaderboard.length
    ? Math.round(leaderboard.reduce((s, e) => s + e.score, 0) / leaderboard.length)
    : 0;

  // Quest type breakdown for chart
  const typeCounts = filteredQuests.reduce<Record<string, number>>((acc, q) => {
    acc[q.questType] = (acc[q.questType] ?? 0) + 1;
    return acc;
  }, {});
  const typeEntries = Object.entries(typeCounts).sort((a, b) => b[1] - a[1]);
  const maxTypeCount = typeEntries[0]?.[1] ?? 1;

  const destById = Object.fromEntries(destinations.map((d) => [d.id, d]));

  const metrics = [
    { label: 'Destinations',   value: destinations.length,             icon: '🗺️',  accent: 'bg-amber-50  text-amber-600'  },
    { label: 'Active Quests',  value: filteredQuests.length,           icon: '📍',  accent: 'bg-orange-50 text-orange-500' },
    { label: 'Top Explorers',  value: leaderboard.length,              icon: '👥',  accent: 'bg-purple-50 text-purple-600' },
    { label: 'Avg XP (Top 10)',value: `${avgXp.toLocaleString()} XP`,  icon: '⭐',  accent: 'bg-yellow-50 text-yellow-600' },
  ];

  return (
    <AuthGuard>
      <div className="flex bg-trail-cream min-h-screen">
        <Sidebar />
        <main className="flex-1 min-w-0">

          <PageHeader title="Analytics" subtitle="Platform performance and engagement metrics" />

          <div className="px-4 md:px-8 py-4 md:py-6 pb-24 md:pb-6 space-y-6">

            {/* Filter */}
            <div className="flex flex-wrap items-center gap-3">
              <select
                value={selectedDestId}
                onChange={(e) => setSelectedDestId(e.target.value)}
                className="px-3 py-2 border border-gray-200 bg-white rounded-xl text-sm
                           focus:outline-none focus:ring-2 focus:ring-trail-orange text-trail-brown"
              >
                <option value="">All Destinations</option>
                {destinations.map((d) => (
                  <option key={d.id} value={d.id}>{d.name}</option>
                ))}
              </select>
              <span className="ml-auto text-xs text-gray-400 font-medium">
                {filteredQuests.length} quest{filteredQuests.length !== 1 ? 's' : ''}
              </span>
            </div>

            {/* Metric cards */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              {loading
                ? [1, 2, 3, 4].map((i) => (
                    <div key={i} className="bg-white rounded-2xl border border-gray-100 p-5 animate-pulse h-28" />
                  ))
                : metrics.map((m) => (
                    <div key={m.label} className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
                      <div className="flex items-start justify-between mb-3">
                        <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide leading-tight">
                          {m.label}
                        </p>
                        <span className={`w-8 h-8 rounded-xl flex items-center justify-center text-base ${m.accent}`}>
                          {m.icon}
                        </span>
                      </div>
                      <p className="text-2xl font-bold text-trail-brown">{m.value}</p>
                    </div>
                  ))}
            </div>

            {/* Middle row */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

              {/* Leaderboard */}
              <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
                <h2 className="text-sm font-bold text-trail-brown mb-4">Top Explorers by XP</h2>
                {loading ? (
                  <div className="space-y-3">
                    {[1, 2, 3, 4, 5].map((i) => (
                      <div key={i} className="h-10 bg-trail-cream rounded-xl animate-pulse" />
                    ))}
                  </div>
                ) : leaderboard.length === 0 ? (
                  <div className="text-center py-10 text-gray-400">
                    <p className="text-3xl mb-2">🏆</p>
                    <p className="text-sm">No explorer data yet.</p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {leaderboard.map((entry) => {
                      const name = entry.user.displayName ?? entry.user.username;
                      const initials = name.slice(0, 2).toUpperCase();
                      const pct = Math.round((entry.score / maxScore) * 100);
                      return (
                        <div key={entry.user.id} className="flex items-center gap-3">
                          {/* Avatar / medal */}
                          <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 text-xs font-bold
                            ${entry.rank <= 3 ? 'bg-trail-peach text-trail-brown' : 'bg-trail-cream text-trail-brown'}`}>
                            {MEDAL[entry.rank] ?? initials}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center justify-between mb-1">
                              <span className="text-xs font-semibold text-trail-brown truncate">{name}</span>
                              <span className="text-xs text-trail-orange font-bold shrink-0 ml-2">
                                {entry.score.toLocaleString()} XP
                              </span>
                            </div>
                            <div className="w-full bg-gray-100 rounded-full h-1.5">
                              <div
                                className="bg-trail-orange h-1.5 rounded-full transition-all"
                                style={{ width: `${pct}%` }}
                              />
                            </div>
                          </div>
                          <span className="text-[10px] text-gray-400 shrink-0">Lv.{entry.user.level}</span>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>

              {/* Quest type breakdown */}
              <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
                <h2 className="text-sm font-bold text-trail-brown mb-4">Quests by Type</h2>
                {loading ? (
                  <div className="space-y-3">
                    {[1, 2, 3, 4].map((i) => (
                      <div key={i} className="h-8 bg-trail-cream rounded-xl animate-pulse" />
                    ))}
                  </div>
                ) : typeEntries.length === 0 ? (
                  <div className="text-center py-10 text-gray-400">
                    <p className="text-3xl mb-2">📍</p>
                    <p className="text-sm">No quests yet.</p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {typeEntries.map(([type, count]) => {
                      const pct = Math.round((count / maxTypeCount) * 100);
                      const label = type.charAt(0).toUpperCase() + type.slice(1);
                      return (
                        <div key={type} className="flex items-center gap-3">
                          <span className="text-lg w-6 text-center shrink-0">{TYPE_ICON[type] ?? '🎯'}</span>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center justify-between mb-1">
                              <span className="text-xs font-semibold text-trail-brown">{label}</span>
                              <span className="text-xs text-gray-400">{count}</span>
                            </div>
                            <div className="w-full bg-gray-100 rounded-full h-2">
                              <div
                                className="bg-trail-orange h-2 rounded-full transition-all"
                                style={{ width: `${pct}%` }}
                              />
                            </div>
                          </div>
                          <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium shrink-0 ${TYPE_COLOR[type] ?? 'bg-gray-100 text-gray-600'}`}>
                            {Math.round((count / (filteredQuests.length || 1)) * 100)}%
                          </span>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>

            {/* Quest table */}
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
              <div className="px-5 py-4 border-b border-gray-100">
                <h2 className="text-sm font-bold text-trail-brown">Quest Overview</h2>
              </div>

              {loading ? (
                <div className="p-5 space-y-3">
                  {[1, 2, 3, 4, 5].map((i) => (
                    <div key={i} className="h-14 bg-trail-cream rounded-xl animate-pulse" />
                  ))}
                </div>
              ) : filteredQuests.length === 0 ? (
                <div className="text-center py-14 text-gray-400">
                  <p className="text-3xl mb-2">📍</p>
                  <p className="text-sm">No quests found.</p>
                </div>
              ) : (
                <>
                  {/* Desktop table */}
                  <div className="hidden md:block overflow-x-auto">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="bg-trail-cream">
                          <th className="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Quest</th>
                          <th className="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Type</th>
                          <th className="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Difficulty</th>
                          <th className="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">XP</th>
                          <th className="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Duration</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-50">
                        {filteredQuests.map((quest) => (
                          <tr key={quest.id} className="hover:bg-trail-cream/50 transition-colors">
                            <td className="px-5 py-3">
                              <p className="font-semibold text-trail-brown text-sm leading-tight">{quest.title}</p>
                              {destById[quest.destinationId]?.name && (
                                <p className="text-xs text-gray-400 mt-0.5">{destById[quest.destinationId]?.name}</p>
                              )}
                            </td>
                            <td className="px-5 py-3">
                              <span className={`text-xs px-2 py-0.5 rounded-full font-medium capitalize ${TYPE_COLOR[quest.questType] ?? 'bg-gray-100 text-gray-600'}`}>
                                {TYPE_ICON[quest.questType] ?? '🎯'} {quest.questType}
                              </span>
                            </td>
                            <td className="px-5 py-3">
                              <span className={`text-xs px-2 py-0.5 rounded-full font-semibold ${DIFF_COLOR[quest.difficulty] ?? 'bg-gray-100 text-gray-600'}`}>
                                {DIFF_LABEL[quest.difficulty] ?? `Lv${quest.difficulty}`}
                              </span>
                            </td>
                            <td className="px-5 py-3 font-bold text-trail-orange text-sm">
                              +{quest.xpReward.toLocaleString()}
                            </td>
                            <td className="px-5 py-3 text-gray-500 text-xs">
                              {quest.estDurationMin ? `⏱ ${quest.estDurationMin} min` : '—'}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  {/* Mobile cards */}
                  <div className="md:hidden divide-y divide-gray-50">
                    {filteredQuests.map((quest) => (
                      <div key={quest.id} className="px-4 py-3 flex items-start gap-3">
                        <span className="text-2xl mt-0.5">{TYPE_ICON[quest.questType] ?? '🎯'}</span>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-trail-brown text-sm leading-tight truncate">{quest.title}</p>
                          <div className="flex items-center gap-2 mt-1 flex-wrap">
                            <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-semibold ${DIFF_COLOR[quest.difficulty] ?? 'bg-gray-100 text-gray-600'}`}>
                              {DIFF_LABEL[quest.difficulty]}
                            </span>
                            {quest.estDurationMin && (
                              <span className="text-[10px] text-gray-400">⏱ {quest.estDurationMin}m</span>
                            )}
                          </div>
                        </div>
                        <span className="text-sm font-bold text-trail-orange shrink-0">+{quest.xpReward}</span>
                      </div>
                    ))}
                  </div>
                </>
              )}
            </div>

          </div>
          <MobileNav />
        </main>
      </div>
    </AuthGuard>
  );
}
