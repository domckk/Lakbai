'use client';

import { Suspense, useEffect, useState } from 'react';
import dynamic from 'next/dynamic';

const QRCodeSVG = dynamic(
  () => import('qrcode.react').then((m) => m.QRCodeSVG),
  { ssr: false },
);
import { useSearchParams } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { MobileNav } from '@/components/MobileNav';
import { PageHeader } from '@/components/PageHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { useStore } from '@/lib/store';
import { apiClient } from '@/lib/api-client';

interface Checkpoint {
  id: string;
  sortOrder: number;
  title: string;
  description: string | null;
  validationType: string;
  geoRadiusM: number | null;
  xpReward: number;
  lat: number | null;
  lng: number | null;
}

interface QuestDetail {
  id: string;
  title: string;
  difficulty: number;
  xpReward: number;
  questType: string;
  checkpoints: Checkpoint[];
}

interface QrToken { token: string; ttlSec: number; }

const VALIDATION_ICON: Record<string, string> = {
  gps: '📍', qr: '🔲', gps_qr: '📍🔲', trivia: '❓',
};
const DIFF_COLOR: Record<number, string> = {
  1: 'bg-green-100 text-green-700', 2: 'bg-green-100 text-green-700',
  3: 'bg-yellow-100 text-yellow-800', 4: 'bg-orange-100 text-orange-700',
  5: 'bg-red-100 text-red-700',
};
const DIFF_LABEL: Record<number, string> = { 1: 'Very Easy', 2: 'Easy', 3: 'Medium', 4: 'Hard', 5: 'Extreme' };
const TYPE_ICON: Record<string, string> = {
  landmark: '🏛️', food: '🍜', cultural: '🎭',
  adventure: '⛰️', heritage: '🏺', nature: '🌿',
};

function CheckpointsContent() {
  const searchParams = useSearchParams();
  const { quests, setQuests, user } = useStore();

  const [selectedQuestId, setSelectedQuestId] = useState(searchParams.get('questId') ?? '');
  const [questDetail, setQuestDetail]         = useState<QuestDetail | null>(null);
  const [questLoading, setQuestLoading]       = useState(false);
  const [qrTokens, setQrTokens]               = useState<Record<string, QrToken>>({});
  const [loadingQr, setLoadingQr]             = useState<string | null>(null);
  const [error, setError]                     = useState<string | null>(null);

  const isPartner = user?.role === 'partner' || user?.role === 'lgu_admin' || user?.role === 'staff';

  useEffect(() => {
    if (quests.length > 0) {
      if (!selectedQuestId) setSelectedQuestId(quests[0].id);
      return;
    }
    apiClient.get('/quests')
      .then((r) => {
        setQuests(r.data);
        if (!selectedQuestId && r.data.length > 0) setSelectedQuestId(r.data[0].id);
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    if (!selectedQuestId) { setQuestDetail(null); return; }
    setQuestLoading(true);
    setError(null);
    apiClient.get(`/quests/${selectedQuestId}`)
      .then((r) => setQuestDetail(r.data))
      .catch(() => setError('Failed to load checkpoints.'))
      .finally(() => setQuestLoading(false));
  }, [selectedQuestId]);

  const handleGetQr = async (checkpointId: string) => {
    setLoadingQr(checkpointId);
    try {
      const r = await apiClient.get(`/checkpoints/${checkpointId}/qr-token`);
      setQrTokens((prev) => ({ ...prev, [checkpointId]: r.data }));
    } finally {
      setLoadingQr(null);
    }
  };

  return (
    <div className="px-4 md:px-8 py-4 md:py-6 pb-24 md:pb-6">
      {/* Quest selector */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4 mb-5">
        <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
          Select Quest
        </label>
        <select
          value={selectedQuestId}
          onChange={(e) => setSelectedQuestId(e.target.value)}
          className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-trail-orange bg-white text-trail-brown"
        >
          <option value="">— Choose a quest —</option>
          {quests.map((q) => (
            <option key={q.id} value={q.id}>
              {TYPE_ICON[q.questType] ?? '🎯'} {q.title}
            </option>
          ))}
        </select>
      </div>

      {!selectedQuestId ? (
        <div className="text-center py-20 text-gray-400">
          <p className="text-5xl mb-3">🔲</p>
          <p className="text-lg font-medium text-trail-brown mb-1">No quest selected</p>
          <p className="text-sm">Pick a quest above to see its checkpoints.</p>
        </div>
      ) : questLoading ? (
        <div className="space-y-3">
          {[1, 2, 3].map((i) => <div key={i} className="h-24 bg-white rounded-2xl animate-pulse border border-gray-100" />)}
        </div>
      ) : error ? (
        <div className="text-center py-10 text-red-400">
          <p className="text-3xl mb-2">⚠️</p><p>{error}</p>
        </div>
      ) : questDetail ? (
        <>
          {/* Quest banner */}
          <div className="bg-trail-brown rounded-2xl p-4 md:p-5 text-white mb-5 flex items-center justify-between gap-4">
            <div className="min-w-0">
              <p className="text-trail-peach text-xs font-medium mb-0.5">Quest</p>
              <h2 className="text-base md:text-lg font-bold truncate">{questDetail.title}</h2>
              <div className="flex items-center gap-2 mt-1.5 flex-wrap">
                <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${DIFF_COLOR[questDetail.difficulty] ?? 'bg-gray-100 text-gray-600'}`}>
                  {DIFF_LABEL[questDetail.difficulty] ?? `Lv${questDetail.difficulty}`}
                </span>
                <span className="text-trail-peach text-xs capitalize">{questDetail.questType}</span>
              </div>
            </div>
            <div className="text-right shrink-0">
              <p className="text-trail-peach text-xs">Quest XP</p>
              <p className="text-2xl font-bold text-trail-orange">+{questDetail.xpReward}</p>
              <p className="text-trail-peach text-xs mt-0.5">
                {questDetail.checkpoints.length} checkpoint{questDetail.checkpoints.length !== 1 ? 's' : ''}
              </p>
            </div>
          </div>

          {questDetail.checkpoints.length === 0 ? (
            <div className="text-center py-10 text-gray-400">
              <p className="text-3xl mb-2">🗺️</p>
              <p className="text-sm">This quest has no checkpoints yet.</p>
            </div>
          ) : (
            <div className="space-y-3">
              {questDetail.checkpoints.map((cp, idx) => {
                const qr    = qrTokens[cp.id];
                const hasQr = cp.validationType?.includes('qr');
                return (
                  <div key={cp.id} className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
                    <div className="flex items-start gap-4 p-4 md:p-5">
                      {/* Step number */}
                      <div className="w-9 h-9 rounded-full bg-trail-orange flex items-center justify-center text-white font-bold text-sm shrink-0 mt-0.5">
                        {idx + 1}
                      </div>

                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <div className="min-w-0">
                            <h3 className="font-bold text-trail-brown text-sm leading-tight">{cp.title}</h3>
                            {cp.description && (
                              <p className="text-xs text-gray-500 mt-0.5 leading-relaxed">{cp.description}</p>
                            )}
                          </div>
                          <span className="text-sm font-bold text-trail-orange shrink-0">+{cp.xpReward} XP</span>
                        </div>

                        <div className="flex items-center gap-2 mt-2 flex-wrap">
                          <span className="text-xs bg-trail-cream text-trail-brown px-2 py-0.5 rounded-full font-medium">
                            {VALIDATION_ICON[cp.validationType] ?? '📍'} {cp.validationType}
                          </span>
                          {cp.geoRadiusM && (
                            <span className="text-xs text-gray-400">±{cp.geoRadiusM}m</span>
                          )}
                          {cp.lat != null && cp.lng != null && (
                            <span className="text-xs text-gray-400 font-mono">
                              {cp.lat.toFixed(5)}, {cp.lng.toFixed(5)}
                            </span>
                          )}
                        </div>

                        {/* QR token section (partners only) */}
                        {isPartner && hasQr && (
                          <div className="mt-3">
                            {qr ? (
                              <div className="bg-trail-cream rounded-xl p-3 flex flex-col sm:flex-row items-center gap-4">
                                {/* Scannable QR code */}
                                <div className="bg-white p-2 rounded-lg shadow-sm shrink-0">
                                  <QRCodeSVG
                                    value={JSON.stringify({ cp: cp.id, t: qr.token })}
                                    size={120}
                                    level="M"
                                  />
                                </div>
                                <div className="flex-1 min-w-0 text-center sm:text-left">
                                  <p className="text-xs font-semibold text-trail-brown mb-1">QR Token</p>
                                  <code className="text-[10px] text-gray-500 font-mono break-all block mb-2">
                                    {qr.token}
                                  </code>
                                  <div className="flex items-center gap-2 flex-wrap justify-center sm:justify-start">
                                    <button
                                      onClick={() => navigator.clipboard.writeText(qr.token)}
                                      className="text-xs text-trail-orange font-semibold hover:text-trail-orange-dark"
                                    >
                                      Copy Token
                                    </button>
                                    <span className="text-[10px] text-gray-400 bg-white px-2 py-0.5 rounded-full">
                                      TTL {qr.ttlSec}s
                                    </span>
                                  </div>
                                </div>
                              </div>
                            ) : (
                              <button
                                onClick={() => handleGetQr(cp.id)}
                                disabled={loadingQr === cp.id}
                                className="text-xs bg-trail-orange text-white px-3 py-1.5 rounded-xl font-medium hover:bg-trail-orange-dark disabled:opacity-60 transition-all active:scale-95"
                              >
                                {loadingQr === cp.id ? 'Generating…' : '🔲 Generate QR Code'}
                              </button>
                            )}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </>
      ) : null}
    </div>
  );
}

export default function CheckpointsPage() {
  return (
    <AuthGuard>
      <div className="flex bg-trail-cream min-h-screen">
        <Sidebar />
        <main className="flex-1 min-w-0">
          <PageHeader
            title="Checkpoints"
            subtitle="View quest checkpoints and generate QR tokens"
          />
          <Suspense fallback={<div className="px-4 md:px-8 py-10 text-gray-400 text-sm">Loading…</div>}>
            <CheckpointsContent />
          </Suspense>
          <MobileNav />
        </main>
      </div>
    </AuthGuard>
  );
}
