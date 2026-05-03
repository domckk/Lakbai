'use client';

import { useEffect, useState } from 'react';
import dynamic from 'next/dynamic';
import { useRouter } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { MobileNav } from '@/components/MobileNav';
import { PageHeader } from '@/components/PageHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { useStore } from '@/lib/store';
import { apiClient } from '@/lib/api-client';

const AnalyticsMap = dynamic(
  () => import('@/components/AnalyticsMap').then((m) => m.AnalyticsMap),
  { ssr: false, loading: () => <div className="w-full h-[280px] bg-trail-cream rounded-2xl animate-pulse" /> },
);

const DestinationMiniMap = dynamic(
  () => import('@/components/DestinationMiniMap').then((m) => m.DestinationMiniMap),
  { ssr: false, loading: () => <div className="w-full h-[160px] bg-trail-cream rounded-xl animate-pulse" /> },
);

interface DestinationDetail {
  id: string;
  slug: string;
  name: string;
  region: string | null;
  countryCode: string;
  heroImageUrl: string | null;
  description: string | null;
  isActive: boolean;
  lat: number | null;
  lng: number | null;
  featuredQuests?: Array<{
    id: string;
    title: string;
    difficulty: number;
    xpReward: number;
    questType: string;
    coverImageUrl: string | null;
  }>;
}

const DIFF_LABEL: Record<number, string> = { 1: 'Very Easy', 2: 'Easy', 3: 'Medium', 4: 'Hard', 5: 'Extreme' };
const DIFF_COLOR: Record<number, string> = {
  1: 'bg-green-100 text-green-700',
  2: 'bg-green-100 text-green-700',
  3: 'bg-yellow-100 text-yellow-700',
  4: 'bg-orange-100 text-orange-700',
  5: 'bg-red-100 text-red-700',
};
const TYPE_ICON: Record<string, string> = {
  landmark: '🏛️', food: '🍜', cultural: '🎭',
  adventure: '⛰️', heritage: '🏺', nature: '🌿',
};

export default function DestinationsPage() {
  const { destinations, quests, setDestinations, setSelectedDestinationId } = useStore();
  const router = useRouter();
  const [loading, setLoading]             = useState(true);
  const [error, setError]                 = useState<string | null>(null);
  const [selected, setSelected]           = useState<DestinationDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);

  useEffect(() => {
    apiClient.get('/destinations')
      .then((r) => setDestinations(r.data))
      .catch((err) => setError(err.response?.data?.message ?? 'Failed to load destinations'))
      .finally(() => setLoading(false));
  }, []);

  const handleSelect = (dest: typeof destinations[0]) => {
    setSelectedDestinationId(dest.id);
    setDetailLoading(true);
    setSelected(null);
    apiClient.get(`/destinations/${dest.slug}`)
      .then((r) => setSelected(r.data))
      .finally(() => setDetailLoading(false));
  };

  const active = destinations.filter((d) => d.isActive);
  const questCountFor = (id: string) => quests.filter((q) => q.destinationId === id).length;

  return (
    <AuthGuard>
      <div className="flex bg-trail-cream min-h-screen">
        <Sidebar />
        <main className="flex-1 min-w-0">

          <PageHeader title="Destinations" subtitle="Explore tourism destinations" />

          <div className="px-4 md:px-8 py-4 md:py-6 pb-24 md:pb-6 space-y-6">

            {/* Map */}
            {!loading && active.length > 0 && (
              <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
                <AnalyticsMap destinations={active} quests={quests} onSelect={handleSelect} />
              </div>
            )}

            {loading ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                {[1, 2, 3, 4, 5, 6].map((i) => (
                  <div key={i} className="bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100 animate-pulse">
                    <div className="h-48 bg-trail-peach opacity-40" />
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
            ) : active.length === 0 ? (
              <div className="text-center py-20 text-gray-400">
                <p className="text-5xl mb-3">🗺️</p>
                <p className="text-lg font-medium text-trail-brown mb-1">No destinations yet</p>
                <p className="text-sm">Destinations will appear here once added.</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                {active.map((dest) => {
                  const qCount = questCountFor(dest.id);
                  return (
                    <div
                      key={dest.id}
                      onClick={() => handleSelect(dest)}
                      className="bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100
                                 hover:shadow-lg hover:border-trail-orange cursor-pointer transition-all group"
                    >
                      {/* Hero image */}
                      <div className="relative w-full h-48 overflow-hidden">
                        {dest.heroImageUrl ? (
                          <img
                            src={dest.heroImageUrl}
                            alt={dest.name}
                            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                          />
                        ) : (
                          <div className="w-full h-full bg-gradient-to-br from-trail-brown to-trail-orange flex items-center justify-center">
                            <span className="text-6xl">🏔️</span>
                          </div>
                        )}
                        {dest.region && (
                          <span className="absolute bottom-3 left-3 bg-black/50 backdrop-blur-sm text-white text-xs px-2.5 py-1 rounded-full font-medium">
                            📍 {dest.region}
                          </span>
                        )}
                        <span className="absolute top-3 right-3 bg-black/40 backdrop-blur-sm text-white text-xs px-2 py-0.5 rounded-full font-medium">
                          {qCount} quest{qCount !== 1 ? 's' : ''}
                        </span>
                      </div>

                      <div className="p-4">
                        <h3 className="font-bold text-trail-brown text-base leading-tight mb-1">{dest.name}</h3>
                        {dest.description && (
                          <p className="text-xs text-gray-500 line-clamp-2 mb-3">{dest.description}</p>
                        )}
                        <span className="text-xs text-trail-orange font-semibold group-hover:underline">
                          Explore →
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
          <MobileNav />
        </main>

        {/* Detail modal — slides up from bottom on mobile */}
        {(selected || detailLoading) && (
          <div
            className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/50 p-0 sm:p-4"
            onClick={() => setSelected(null)}
          >
            <div
              className="bg-white rounded-t-3xl sm:rounded-2xl shadow-2xl w-full sm:max-w-lg max-h-[90vh] overflow-y-auto"
              onClick={(e) => e.stopPropagation()}
            >
              {detailLoading ? (
                <div className="p-10 text-center text-gray-400 animate-pulse">Loading…</div>
              ) : selected ? (
                <>
                  <div className="relative w-full h-56">
                    {selected.heroImageUrl ? (
                      <img
                        src={selected.heroImageUrl}
                        alt={selected.name}
                        className="w-full h-full object-cover rounded-t-3xl sm:rounded-t-2xl"
                      />
                    ) : (
                      <div className="w-full h-full bg-gradient-to-br from-trail-brown to-trail-orange flex items-center justify-center rounded-t-3xl sm:rounded-t-2xl">
                        <span className="text-7xl">🏔️</span>
                      </div>
                    )}
                    <button
                      onClick={() => setSelected(null)}
                      className="absolute top-3 right-3 bg-black/40 backdrop-blur-sm text-white w-8 h-8 rounded-full flex items-center justify-center text-xl leading-none hover:bg-black/60 transition-colors"
                    >
                      ×
                    </button>
                    {selected.region && (
                      <span className="absolute bottom-3 left-4 bg-black/50 backdrop-blur-sm text-white text-xs px-2.5 py-1 rounded-full font-medium">
                        📍 {selected.region}
                      </span>
                    )}
                  </div>

                  <div className="p-5 pb-8">
                    <h2 className="text-xl font-bold text-trail-brown mb-2">{selected.name}</h2>
                    {selected.description && (
                      <p className="text-sm text-gray-600 mb-4 leading-relaxed">{selected.description}</p>
                    )}

                    {/* Location map */}
                    <div className="mb-5">
                      <h3 className="font-bold text-trail-brown text-sm mb-2">Location</h3>
                      <DestinationMiniMap
                        name={selected.name}
                        region={selected.region}
                        lat={selected.lat ?? null}
                        lng={selected.lng ?? null}
                      />
                    </div>

                    {selected.featuredQuests && selected.featuredQuests.length > 0 && (
                      <div>
                        <h3 className="font-bold text-trail-brown text-sm mb-3">Available Quests</h3>
                        <div className="space-y-2">
                          {selected.featuredQuests.map((q) => (
                            <div
                              key={q.id}
                              onClick={() => router.push(`/checkpoints?questId=${q.id}`)}
                              className="flex items-center gap-3 p-3 bg-trail-cream rounded-xl cursor-pointer
                                         hover:bg-trail-peach hover:shadow-sm transition-all group"
                            >
                              <div className="w-10 h-10 rounded-lg bg-white flex items-center justify-center text-xl shadow-sm shrink-0">
                                {TYPE_ICON[q.questType] ?? '🎯'}
                              </div>
                              <div className="flex-1 min-w-0">
                                <p className="text-sm font-semibold text-trail-brown truncate group-hover:text-trail-orange transition-colors">{q.title}</p>
                                <span className={`text-xs px-1.5 py-0.5 rounded font-medium ${DIFF_COLOR[q.difficulty] ?? 'bg-gray-100 text-gray-600'}`}>
                                  {DIFF_LABEL[q.difficulty] ?? `Lv${q.difficulty}`}
                                </span>
                              </div>
                              <div className="flex items-center gap-1.5 shrink-0">
                                <span className="text-sm font-bold text-trail-orange">+{q.xpReward} XP</span>
                                <span className="text-trail-orange text-xs opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                              </div>
                            </div>
                          ))}
                        </div>
                        <button
                          onClick={() => router.push('/quests')}
                          className="mt-4 w-full py-2.5 rounded-xl bg-trail-orange text-white text-sm font-semibold
                                     hover:bg-trail-orange-dark transition-colors active:scale-95"
                        >
                          View all quests →
                        </button>
                      </div>
                    )}
                  </div>
                </>
              ) : null}
            </div>
          </div>
        )}
      </div>
    </AuthGuard>
  );
}
