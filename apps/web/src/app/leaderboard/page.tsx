'use client';

import { useEffect, useState } from 'react';
import { Sidebar } from '@/components/Sidebar';
import { MobileNav } from '@/components/MobileNav';
import { PageHeader } from '@/components/PageHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { apiClient } from '@/lib/api-client';

interface LeaderboardEntry {
  rank: number;
  score: number;
  user: { id: string; username: string; displayName: string | null; level: number; avatarUrl: string | null };
}

const MEDAL = ['🥇', '🥈', '🥉'];
const SCOPES = [
  { key: 'global', label: 'All-Time Global' },
  { key: 'weekly', label: 'This Week' },
];

export default function LeaderboardPage() {
  const [scope, setScope] = useState('global');
  const [entries, setEntries] = useState<LeaderboardEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);
    apiClient
      .get(`/leaderboards/${scope}?limit=50`)
      .then((r) => setEntries(r.data))
      .catch(() => setError('Failed to load leaderboard.'))
      .finally(() => setLoading(false));
  }, [scope]);

  const top3 = entries.slice(0, 3);
  const rest = entries.slice(3);
  const maxScore = entries[0]?.score ?? 1;

  return (
    <AuthGuard>
      <div className="flex bg-trail-cream min-h-screen">
        <Sidebar />
        <main className="flex-1 min-w-0">

          <PageHeader
            title="🏆 Leaderboard"
            subtitle="Top explorers ranked by XP earned"
            right={
              <div className="flex bg-trail-cream rounded-lg p-1 gap-1">
                {SCOPES.map((s) => (
                  <button
                    key={s.key}
                    onClick={() => setScope(s.key)}
                    className={`px-3 py-1.5 rounded-md text-xs font-medium transition-all ${
                      scope === s.key ? 'bg-trail-orange text-white shadow-sm' : 'text-trail-brown hover:bg-white'
                    }`}
                  >
                    {s.label}
                  </button>
                ))}
              </div>
            }
          />

          <div className="px-4 md:px-8 py-4 md:py-6 pb-24 md:pb-6 max-w-3xl">
            {loading ? (
              <div className="space-y-3">
                {[1, 2, 3, 4, 5].map((i) => (
                  <div key={i} className="h-16 bg-white rounded-xl animate-pulse border border-gray-100" />
                ))}
              </div>
            ) : error ? (
              <div className="text-center py-20 text-red-400">
                <p className="text-4xl mb-2">⚠️</p>
                <p>{error}</p>
              </div>
            ) : entries.length === 0 ? (
              <div className="text-center py-20 text-gray-400">
                <p className="text-5xl mb-3">🏅</p>
                <p className="text-lg font-medium text-trail-brown mb-1">No data yet</p>
                <p className="text-sm">Leaderboard populates once users complete quests.</p>
              </div>
            ) : (
              <>
                {/* Podium top 3 */}
                {top3.length > 0 && (
                  <div className="flex items-end justify-center gap-4 mb-8">
                    {[top3[1], top3[0], top3[2]].filter((e): e is LeaderboardEntry => !!e).map((e, i) => {
                      const actualRank = e.rank;
                      const heights = ['h-28', 'h-36', 'h-24'] as const;
                      const podiumOrder = [1, 0, 2] as const;
                      const height = heights[podiumOrder[i as 0 | 1 | 2]];
                      return (
                        <div key={e.user.id} className="flex flex-col items-center">
                          <div className="w-12 h-12 rounded-full bg-trail-peach flex items-center justify-center text-xl font-bold text-trail-brown mb-2 border-2 border-trail-orange">
                            {e.user.username[0]?.toUpperCase() ?? '?'}
                          </div>
                          <p className="text-xs font-semibold text-trail-brown text-center truncate max-w-[80px]">
                            {e.user.displayName ?? e.user.username}
                          </p>
                          <p className="text-xs text-trail-orange font-bold mt-0.5">
                            {e.score.toLocaleString()} XP
                          </p>
                          <div
                            className={`${height} w-20 rounded-t-lg flex items-center justify-center mt-2 ${
                              actualRank === 1
                                ? 'bg-yellow-400'
                                : actualRank === 2
                                ? 'bg-gray-300'
                                : 'bg-orange-300'
                            }`}
                          >
                            <span className="text-2xl">{MEDAL[actualRank - 1]}</span>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}

                {/* Full table */}
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                  <div className="divide-y divide-gray-50">
                    {entries.map((e, i) => (
                      <div key={e.user.id} className="flex items-center gap-4 px-5 py-3.5 hover:bg-trail-cream transition-colors">
                        <div className={`w-8 h-8 flex items-center justify-center text-sm font-bold rounded-full shrink-0 ${
                          i < 3 ? 'bg-trail-peach' : 'bg-gray-100 text-gray-500'
                        }`}>
                          {i < 3 ? MEDAL[i] : `#${e.rank}`}
                        </div>
                        <div className="w-8 h-8 rounded-full bg-trail-orange flex items-center justify-center text-white text-xs font-bold shrink-0">
                          {e.user.username[0]?.toUpperCase() ?? '?'}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-semibold text-trail-brown truncate">
                            {e.user.displayName ?? e.user.username}
                          </p>
                          <p className="text-xs text-gray-400">Level {e.user.level} Explorer</p>
                        </div>
                        <div className="text-right shrink-0">
                          <p className="text-sm font-bold text-trail-orange">{e.score.toLocaleString()} XP</p>
                          <div className="w-24 bg-gray-100 rounded-full h-1 mt-1">
                            <div
                              className="bg-trail-orange h-1 rounded-full"
                              style={{ width: `${(e.score / maxScore) * 100}%` }}
                            />
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </>
            )}
          </div>
          <MobileNav />
        </main>
      </div>
    </AuthGuard>
  );
}
