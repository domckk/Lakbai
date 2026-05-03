'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { MobileNav } from '@/components/MobileNav';
import { PageHeader } from '@/components/PageHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { useStore } from '@/lib/store';
import { apiClient } from '@/lib/api-client';

const DIFF_LABEL: Record<number, string> = { 1: 'Very Easy', 2: 'Easy', 3: 'Medium', 4: 'Hard', 5: 'Extreme' };
const DIFF_COLOR: Record<number, string> = {
  1: 'bg-green-100 text-green-700',
  2: 'bg-green-100 text-green-700',
  3: 'bg-yellow-100 text-yellow-800',
  4: 'bg-orange-100 text-orange-700',
  5: 'bg-red-100 text-red-700',
};
const TYPE_ICON: Record<string, string> = {
  landmark: '🏛️', food: '🍜', cultural: '🎭',
  adventure: '⛰️', shopping: '🛍️', heritage: '🏺', nature: '🌿',
};
const TYPE_GRADIENT: Record<string, string> = {
  landmark:  'from-amber-800  to-amber-600',
  food:      'from-orange-600 to-yellow-500',
  cultural:  'from-purple-800 to-purple-600',
  adventure: 'from-teal-800   to-teal-600',
  heritage:  'from-stone-700  to-amber-700',
  nature:    'from-green-800  to-green-600',
  shopping:  'from-pink-600   to-pink-400',
};

export default function QuestsPage() {
  const router = useRouter();
  const { quests, destinations, setQuests, setDestinations, selectedDestinationId } = useStore();
  const [loading, setLoading]       = useState(true);
  const [error, setError]           = useState<string | null>(null);
  const [filterType, setFilterType] = useState('');
  const [filterDiff, setFilterDiff] = useState('');

  useEffect(() => {
    Promise.all([apiClient.get('/quests'), apiClient.get('/destinations')])
      .then(([q, d]) => { setQuests(q.data); setDestinations(d.data); })
      .catch((err) => setError(err.response?.data?.message ?? 'Failed to load quests'))
      .finally(() => setLoading(false));
  }, []);

  const selectedDestination = destinations.find((d) => d.id === selectedDestinationId) ?? null;

  const destinationQuests = selectedDestinationId
    ? quests.filter((q) => q.destinationId === selectedDestinationId)
    : [];

  const questTypes = [...new Set(destinationQuests.map((q) => q.questType))];

  const filtered = destinationQuests.filter((q) => {
    if (filterType && q.questType !== filterType)          return false;
    if (filterDiff && q.difficulty !== Number(filterDiff)) return false;
    return true;
  });

  const hasFilters = filterType || filterDiff;

  if (!loading && !selectedDestinationId) {
    return (
      <AuthGuard>
        <div className="flex bg-trail-cream min-h-screen">
          <Sidebar />
          <main className="flex-1 min-w-0">
            <PageHeader title="Quests" subtitle="Pick a mission and start exploring" />
            <div className="flex flex-col items-center justify-center py-32 px-6 text-center">
              <p className="text-6xl mb-4">🗺️</p>
              <h2 className="text-xl font-bold text-trail-brown mb-2">Choose a destination first</h2>
              <p className="text-sm text-gray-500 mb-6 max-w-xs">
                Quests are tied to a destination. Pick one to see the missions available there.
              </p>
              <button
                onClick={() => router.push('/destinations')}
                className="px-6 py-3 rounded-xl bg-trail-orange text-white font-semibold text-sm
                           hover:bg-trail-orange-dark transition-colors active:scale-95"
              >
                Browse Destinations →
              </button>
            </div>
            <MobileNav />
          </main>
        </div>
      </AuthGuard>
    );
  }

  return (
    <AuthGuard>
      <div className="flex bg-trail-cream min-h-screen">
        <Sidebar />
        <main className="flex-1 min-w-0">

          <PageHeader
            title="Quests"
            subtitle={selectedDestination ? `Exploring ${selectedDestination.name}` : 'Pick a mission and start exploring'}
          />

          <div className="px-4 md:px-8 py-4 md:py-6 pb-24 md:pb-6">

            {/* Destination banner */}
            {selectedDestination && (
              <div className="flex items-center justify-between gap-3 bg-white border border-gray-100 rounded-xl px-4 py-3 mb-4 shadow-sm">
                <div className="flex items-center gap-2 min-w-0">
                  <span className="text-lg">📍</span>
                  <div className="min-w-0">
                    <p className="text-xs text-gray-400 font-medium leading-none mb-0.5">Current destination</p>
                    <p className="text-sm font-bold text-trail-brown truncate">{selectedDestination.name}</p>
                  </div>
                </div>
                <button
                  onClick={() => router.push('/destinations')}
                  className="shrink-0 text-xs font-semibold text-trail-orange hover:underline"
                >
                  Change →
                </button>
              </div>
            )}

            {/* Filters — type + difficulty only */}
            <div className="flex flex-wrap gap-2 items-center mb-5">
              <select
                value={filterType}
                onChange={(e) => setFilterType(e.target.value)}
                className="px-3 py-2 border border-gray-200 bg-white rounded-xl text-sm
                           focus:outline-none focus:ring-2 focus:ring-trail-orange text-trail-brown"
              >
                <option value="">All Types</option>
                {questTypes.map((t) => (
                  <option key={t} value={t}>{TYPE_ICON[t] ?? '🎯'} {t.charAt(0).toUpperCase() + t.slice(1)}</option>
                ))}
              </select>

              <select
                value={filterDiff}
                onChange={(e) => setFilterDiff(e.target.value)}
                className="px-3 py-2 border border-gray-200 bg-white rounded-xl text-sm
                           focus:outline-none focus:ring-2 focus:ring-trail-orange text-trail-brown"
              >
                <option value="">All Difficulties</option>
                {[1, 2, 3, 4, 5].map((d) => <option key={d} value={d}>{DIFF_LABEL[d]}</option>)}
              </select>

              {hasFilters && (
                <button
                  onClick={() => { setFilterType(''); setFilterDiff(''); }}
                  className="text-xs text-trail-orange font-semibold hover:underline"
                >
                  Clear
                </button>
              )}

              <span className="ml-auto text-xs text-gray-400 font-medium">
                {filtered.length} quest{filtered.length !== 1 ? 's' : ''}
              </span>
            </div>

            {loading ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
                {[1, 2, 3, 4, 5, 6].map((i) => (
                  <div key={i} className="bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100 animate-pulse">
                    <div className="h-44 bg-trail-peach opacity-40" />
                    <div className="p-4 space-y-2">
                      <div className="h-4 bg-trail-cream rounded w-3/4" />
                      <div className="h-3 bg-trail-cream rounded w-1/2" />
                    </div>
                  </div>
                ))}
              </div>
            ) : error ? (
              <div className="text-center py-20 text-red-400">
                <p className="text-4xl mb-2">⚠️</p><p>{error}</p>
              </div>
            ) : filtered.length === 0 ? (
              <div className="text-center py-20 text-gray-400">
                <p className="text-5xl mb-3">📍</p>
                <p className="text-lg font-medium text-trail-brown mb-1">No quests found</p>
                <p className="text-sm">
                  {hasFilters
                    ? 'Try adjusting your filters.'
                    : `No quests available for ${selectedDestination?.name ?? 'this destination'} yet.`}
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
                {filtered.map((quest) => {
                  const gradient  = TYPE_GRADIENT[quest.questType] ?? 'from-trail-brown to-trail-orange';
                  const typeLabel = quest.questType.charAt(0).toUpperCase() + quest.questType.slice(1);

                  return (
                    <div
                      key={quest.id}
                      onClick={() => router.push(`/checkpoints?questId=${quest.id}`)}
                      className="bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100
                                 hover:shadow-lg hover:border-trail-orange transition-all cursor-pointer group"
                    >
                      {/* Cover */}
                      <div className="relative w-full h-44 overflow-hidden">
                        {quest.coverImageUrl ? (
                          <img
                            src={quest.coverImageUrl}
                            alt={quest.title}
                            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                          />
                        ) : (
                          <div className={`w-full h-full bg-gradient-to-br ${gradient} flex items-center justify-center`}>
                            <span className="text-6xl drop-shadow-lg">{TYPE_ICON[quest.questType] ?? '🎯'}</span>
                          </div>
                        )}

                        {/* Difficulty — top left */}
                        <span className={`absolute top-3 left-3 text-xs px-2.5 py-1 rounded-full font-semibold shadow-sm ${DIFF_COLOR[quest.difficulty] ?? 'bg-gray-100 text-gray-600'}`}>
                          {DIFF_LABEL[quest.difficulty]}
                        </span>

                        {/* Premium — top right */}
                        {quest.isPremium && (
                          <span className="absolute top-3 right-3 bg-purple-600 text-white text-xs px-2 py-0.5 rounded-full font-semibold shadow-sm">
                            ⭐ Premium
                          </span>
                        )}

                        {/* Bottom gradient for legibility */}
                        <div className="absolute bottom-0 inset-x-0 h-16 bg-gradient-to-t from-black/60 to-transparent" />

                        {/* XP + duration — bottom */}
                        <div className="absolute bottom-3 inset-x-3 flex items-center justify-between">
                          <span className="text-white/80 text-xs font-medium">
                            {quest.estDurationMin ? `⏱ ${quest.estDurationMin} min` : ''}
                          </span>
                          <span className="text-trail-orange font-bold text-sm drop-shadow">
                            +{quest.xpReward} XP
                          </span>
                        </div>
                      </div>

                      {/* Body */}
                      <div className="p-4">
                        <div className="flex items-start justify-between gap-2 mb-1.5">
                          <h3 className="font-bold text-trail-brown text-sm leading-snug">{quest.title}</h3>
                          <span className="shrink-0 text-xs bg-trail-cream text-trail-brown px-2 py-0.5 rounded-full font-medium">
                            {TYPE_ICON[quest.questType]} {typeLabel}
                          </span>
                        </div>
                        <p className="text-xs text-gray-500 line-clamp-2 leading-relaxed">
                          {quest.summary ?? 'No description available.'}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
          <MobileNav />
        </main>
      </div>
    </AuthGuard>
  );
}
