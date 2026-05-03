'use client';

import { useEffect, useState } from 'react';
import dynamic from 'next/dynamic';
import { Sidebar } from '@/components/Sidebar';
import { MobileNav } from '@/components/MobileNav';
import { PageHeader } from '@/components/PageHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { apiClient } from '@/lib/api-client';


interface PassportSummary {
  id: string;
  title: string;
  coverUrl: string | null;
  themeColor: string | null;
  totalStamps: number;
  earnedStamps: number;
  completion: number;
}

interface StampDetail {
  id: string;
  name: string;
  rarity: string | null;
  artUrl: string | null;
  earnedAt: string | null;
  lat: number | null;
  lng: number | null;
}

interface PassportDetail extends PassportSummary {
  stamps: StampDetail[];
}

const RARITY_RING: Record<string, string> = {
  common:    'ring-gray-200   bg-gray-50',
  uncommon:  'ring-green-300  bg-green-50',
  rare:      'ring-blue-300   bg-blue-50',
  epic:      'ring-purple-300 bg-purple-50',
  legendary: 'ring-yellow-400 bg-yellow-50',
};
const RARITY_BADGE: Record<string, string> = {
  common:    'bg-gray-100    text-gray-600',
  uncommon:  'bg-green-100   text-green-700',
  rare:      'bg-blue-100    text-blue-700',
  epic:      'bg-purple-100  text-purple-700',
  legendary: 'bg-yellow-100  text-yellow-700',
};
const RARITY_ICON: Record<string, string> = {
  common: '🔖', uncommon: '🌟', rare: '🔷', epic: '💎', legendary: '⭐',
};

export default function PassportsPage() {
  const [passports, setPassports]         = useState<PassportSummary[]>([]);
  const [loading, setLoading]             = useState(true);
  const [selected, setSelected]           = useState<PassportDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [error, setError]                 = useState<string | null>(null);

  useEffect(() => {
    apiClient.get('/me/passports')
      .then((r) => {
        const data: PassportSummary[] = r.data;
        const unique = data.filter((p, i, arr) => arr.findIndex((x) => x.id === p.id) === i);
        setPassports(unique);
      })
      .catch(() => setError('Failed to load passports.'))
      .finally(() => setLoading(false));
  }, []);

  const handleOpen = (p: PassportSummary) => {
    setDetailLoading(true);
    apiClient.get(`/me/passports/${p.id}`)
      .then((r) => setSelected(r.data))
      .finally(() => setDetailLoading(false));
  };

  return (
    <AuthGuard>
      <div className="flex bg-trail-cream min-h-screen">
        <Sidebar />
        <main className="flex-1 min-w-0">

          <PageHeader title="Passports" subtitle="Collect stamps by completing checkpoints" />

          <div className="px-4 md:px-8 py-4 md:py-6 pb-24 md:pb-6">
            {loading ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                {[1, 2, 3].map((i) => (
                  <div key={i} className="h-56 bg-white rounded-2xl animate-pulse border border-gray-100" />
                ))}
              </div>
            ) : error ? (
              <div className="text-center py-20 text-red-400">
                <p className="text-4xl mb-2">⚠️</p><p>{error}</p>
              </div>
            ) : passports.length === 0 ? (
              <div className="text-center py-20 text-gray-400">
                <p className="text-5xl mb-3">📖</p>
                <p className="text-lg font-medium text-trail-brown mb-1">No passports yet</p>
                <p className="text-sm">Complete checkpoints to collect stamps!</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                {passports.map((p) => {
                  const isComplete = p.earnedStamps >= p.totalStamps && p.totalStamps > 0;
                  return (
                    <div
                      key={p.id}
                      onClick={() => handleOpen(p)}
                      className="bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100
                                 hover:shadow-lg hover:border-trail-orange cursor-pointer transition-all group"
                    >
                      {/* Cover */}
                      <div className="relative w-full h-44 overflow-hidden">
                        {p.coverUrl ? (
                          <img
                            src={p.coverUrl}
                            alt={p.title}
                            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                          />
                        ) : (
                          <div
                            className="w-full h-full flex flex-col items-center justify-center gap-2"
                            style={{ backgroundColor: p.themeColor ?? '#4A2C17' }}
                          >
                            <span className="text-5xl">📖</span>
                            <span className="text-white/70 text-xs font-medium uppercase tracking-widest">
                              Digital Passport
                            </span>
                          </div>
                        )}
                        {isComplete && (
                          <span className="absolute top-3 right-3 bg-green-500 text-white text-xs font-bold px-2.5 py-1 rounded-full shadow">
                            ✓ Complete
                          </span>
                        )}
                        <div className="absolute bottom-0 inset-x-0 h-12 bg-gradient-to-t from-black/50 to-transparent" />
                        <span className="absolute bottom-3 left-3 text-white text-xs font-semibold">
                          {p.earnedStamps} / {p.totalStamps} stamps
                        </span>
                      </div>

                      <div className="px-4 py-3">
                        <h3 className="font-bold text-trail-brown text-sm truncate">{p.title}</h3>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
          <MobileNav />
        </main>

        {/* Stamp detail modal */}
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
                <div className="p-10 text-center text-gray-400 animate-pulse">Loading passport…</div>
              ) : selected ? (
                <>
                  {/* Header */}
                  <div className="relative w-full h-44">
                    {selected.coverUrl ? (
                      <img
                        src={selected.coverUrl}
                        alt={selected.title}
                        className="w-full h-full object-cover rounded-t-3xl sm:rounded-t-2xl"
                      />
                    ) : (
                      <div
                        className="w-full h-full flex items-center justify-center rounded-t-3xl sm:rounded-t-2xl"
                        style={{ backgroundColor: selected.themeColor ?? '#4A2C17' }}
                      >
                        <span className="text-6xl">📖</span>
                      </div>
                    )}
                    <button
                      onClick={() => setSelected(null)}
                      className="absolute top-3 right-3 bg-black/40 backdrop-blur-sm text-white w-8 h-8 rounded-full flex items-center justify-center text-xl leading-none hover:bg-black/60 transition-colors"
                    >
                      ×
                    </button>
                  </div>

                  <div className="p-5 pb-8">
                    <div className="flex items-start justify-between mb-1">
                      <h2 className="text-lg font-bold text-trail-brown">{selected.title}</h2>
                    </div>
                    <p className="text-sm text-gray-500 mb-4">
                      {selected.earnedStamps} of {selected.totalStamps} stamps collected
                    </p>


                    {/* Stamps */}
                    {(() => {
                      const unique = selected.stamps.filter(
                        (s, i, arr) => arr.findIndex((x) => x.id === s.id) === i,
                      );
                      const removed = selected.stamps.length - unique.length;
                      return (
                        <div className="grid grid-cols-3 gap-3">
                          {unique.map((s) => {
                            const earned = !!s.earnedAt;
                            const rarity = s.rarity ?? 'common';
                            return (
                              <div
                                key={s.id}
                                className={`rounded-2xl ring-2 p-3 flex flex-col items-center text-center transition-all
                                  ${earned ? RARITY_RING[rarity] ?? RARITY_RING.common : 'ring-gray-200 bg-gray-50 opacity-40'}`}
                              >
                                <div className="w-12 h-12 rounded-xl bg-white flex items-center justify-center mb-2 shadow-sm">
                                  {s.artUrl && earned ? (
                                    <img src={s.artUrl} alt={s.name} className="w-10 h-10 object-contain rounded-lg" />
                                  ) : (
                                    <span className="text-2xl">{earned ? (RARITY_ICON[rarity] ?? '🔖') : '🔒'}</span>
                                  )}
                                </div>
                                <p className="text-xs font-semibold text-trail-brown leading-tight">{s.name}</p>
                                {earned ? (
                                  <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-medium mt-1 capitalize ${RARITY_BADGE[rarity] ?? RARITY_BADGE.common}`}>
                                    {rarity}
                                  </span>
                                ) : (
                                  <span className="text-[10px] text-gray-400 mt-1">Locked</span>
                                )}
                              </div>
                            );
                          })}
                          {removed > 0 && Array.from({ length: removed }).map((_, i) => (
                            <div
                              key={`mystery-${i}`}
                              className="rounded-2xl ring-2 ring-dashed ring-trail-orange/40 bg-trail-cream/60 p-3 flex flex-col items-center text-center"
                            >
                              <div className="w-12 h-12 rounded-xl bg-white flex items-center justify-center mb-2 shadow-sm">
                                <span className="text-2xl">✨</span>
                              </div>
                              <p className="text-xs font-semibold text-trail-brown/50 leading-tight">More coming</p>
                              <span className="text-[10px] text-trail-orange mt-1">Stay tuned</span>
                            </div>
                          ))}
                        </div>
                      );
                    })()}

                    {selected.earnedStamps >= selected.totalStamps && selected.totalStamps > 0 && (
                      <div className="mt-5 bg-green-50 border border-green-200 rounded-2xl p-4 text-center">
                        <p className="text-3xl mb-1">🎉</p>
                        <p className="text-sm font-bold text-green-700">Passport Complete!</p>
                        <p className="text-xs text-green-600 mt-1">You've collected all stamps.</p>
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
