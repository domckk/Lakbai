'use client';

import { useEffect, useState } from 'react';
import { Sidebar } from '@/components/Sidebar';
import { MobileNav } from '@/components/MobileNav';
import { PageHeader } from '@/components/PageHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { apiClient } from '@/lib/api-client';

interface AvailableReward {
  id: string;
  title: string;
  description: string | null;
  reward_type: string;
  value_pct: number | null;
  partner_id: string | null;
  required_quest_id: string | null;
  unlocked: boolean;
}

interface WalletReward {
  id: number;
  reward_id: string;
  title: string;
  description: string | null;
  redemption_code: string;
  status: string;
  issued_at: string;
}

const TYPE_ICON: Record<string, string> = {
  discount: '💸',
  freebie: '🎁',
  voucher: '🎟️',
  exclusive: '⭐',
  digital: '🖼️',
};

export default function RewardsPage() {
  const [tab, setTab] = useState<'available' | 'wallet'>('available');
  const [available, setAvailable] = useState<AvailableReward[]>([]);
  const [wallet, setWallet] = useState<WalletReward[]>([]);
  const [loading, setLoading] = useState(true);
  const [redeeming, setRedeeming] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  useEffect(() => {
    setLoading(true);
    Promise.all([apiClient.get('/rewards'), apiClient.get('/me/rewards')])
      .then(([a, w]) => {
        setAvailable(a.data);
        setWallet(w.data);
      })
      .catch(() => setError('Failed to load rewards.'))
      .finally(() => setLoading(false));
  }, []);

  const handleRedeem = async (rewardId: string) => {
    setRedeeming(rewardId);
    try {
      const res = await apiClient.post(`/me/rewards/${rewardId}/redeem`);
      setWallet((prev) => {
        const r = available.find((a) => a.id === rewardId);
        if (!r) return prev;
        return [
          { id: res.data.id, reward_id: rewardId, title: r.title, description: r.description,
            redemption_code: res.data.redemptionCode, status: 'issued', issued_at: new Date().toISOString() },
          ...prev,
        ];
      });
      showToast('Reward claimed! Check your Wallet tab.');
      setTab('wallet');
    } catch (e: any) {
      showToast(e.response?.data?.message ?? 'Could not redeem reward.');
    } finally {
      setRedeeming(null);
    }
  };

  const copyCode = (code: string) => {
    navigator.clipboard.writeText(code);
    showToast('Code copied to clipboard!');
  };

  return (
    <AuthGuard>
      <div className="flex bg-trail-cream min-h-screen">
        <Sidebar />
        <main className="flex-1 min-w-0">

          {/* Toast */}
          {toast && (
            <div className="fixed top-5 right-5 z-[100] bg-trail-brown text-white text-sm px-4 py-2.5 rounded-xl shadow-lg animate-fade-in">
              {toast}
            </div>
          )}

          <PageHeader
            title="🎁 Rewards"
            subtitle="Unlock perks and track your vouchers"
            right={
              <div className="flex bg-trail-cream rounded-lg p-1 gap-1">
                {(['available', 'wallet'] as const).map((t) => (
                  <button
                    key={t}
                    onClick={() => setTab(t)}
                    className={`px-3 py-1.5 rounded-md text-xs font-medium transition-all capitalize ${
                      tab === t ? 'bg-trail-orange text-white shadow-sm' : 'text-trail-brown hover:bg-white'
                    }`}
                  >
                    {t === 'wallet' ? `🎟️ Wallet (${wallet.length})` : '🏪 Available'}
                  </button>
                ))}
              </div>
            }
          />

          <div className="px-4 md:px-8 py-4 md:py-6 pb-24 md:pb-6">
            {loading ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                {[1, 2, 3, 4, 5, 6].map((i) => (
                  <div key={i} className="h-36 bg-white rounded-xl animate-pulse border border-gray-100" />
                ))}
              </div>
            ) : error ? (
              <div className="text-center py-20 text-red-400">
                <p className="text-4xl mb-2">⚠️</p>
                <p>{error}</p>
              </div>
            ) : tab === 'available' ? (
              available.length === 0 ? (
                <div className="text-center py-20 text-gray-400">
                  <p className="text-5xl mb-3">🎁</p>
                  <p className="text-lg font-medium text-trail-brown mb-1">No rewards available</p>
                  <p className="text-sm">Partners add rewards — check back soon.</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                  {available.map((r) => {
                    const alreadyClaimed = wallet.some((w) => w.reward_id === r.id);
                    return (
                      <div
                        key={r.id}
                        className={`bg-white rounded-xl border p-5 shadow-sm transition-all ${
                          r.unlocked ? 'border-gray-100 hover:border-trail-orange hover:shadow-md' : 'border-dashed border-gray-200 opacity-60'
                        }`}
                      >
                        <div className="flex items-start justify-between mb-3">
                          <span className="text-2xl">{TYPE_ICON[r.reward_type] ?? '🎁'}</span>
                          {!r.unlocked && (
                            <span className="text-xs bg-gray-100 text-gray-500 px-2 py-0.5 rounded-full font-medium">
                              🔒 Locked
                            </span>
                          )}
                          {r.unlocked && r.value_pct && (
                            <span className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded-full font-bold">
                              {r.value_pct}% OFF
                            </span>
                          )}
                        </div>
                        <h3 className="font-bold text-trail-brown text-sm mb-1">{r.title}</h3>
                        {r.description && (
                          <p className="text-xs text-gray-500 line-clamp-2 mb-3">{r.description}</p>
                        )}
                        {!r.unlocked && r.required_quest_id && (
                          <p className="text-xs text-amber-600 mb-3">Complete the required quest to unlock.</p>
                        )}
                        <button
                          onClick={() => r.unlocked && !alreadyClaimed && handleRedeem(r.id)}
                          disabled={!r.unlocked || alreadyClaimed || redeeming === r.id}
                          className={`w-full py-2 rounded-lg text-xs font-semibold transition-all ${
                            alreadyClaimed
                              ? 'bg-gray-100 text-gray-400 cursor-default'
                              : r.unlocked
                              ? 'bg-trail-orange text-white hover:bg-trail-orange-dark disabled:opacity-60'
                              : 'bg-gray-100 text-gray-400 cursor-not-allowed'
                          }`}
                        >
                          {redeeming === r.id ? 'Claiming…' : alreadyClaimed ? '✓ Already Claimed' : r.unlocked ? 'Claim Reward' : 'Locked'}
                        </button>
                      </div>
                    );
                  })}
                </div>
              )
            ) : (
              /* Wallet tab */
              wallet.length === 0 ? (
                <div className="text-center py-20 text-gray-400">
                  <p className="text-5xl mb-3">🎟️</p>
                  <p className="text-lg font-medium text-trail-brown mb-1">Your wallet is empty</p>
                  <p className="text-sm">Claim rewards from the Available tab to see them here.</p>
                </div>
              ) : (
                <div className="space-y-3 max-w-2xl">
                  {wallet.map((w) => (
                    <div
                      key={w.id}
                      className={`bg-white rounded-xl border shadow-sm p-5 flex items-center gap-4 ${
                        w.status === 'redeemed' ? 'opacity-50' : 'border-gray-100'
                      }`}
                    >
                      <div className="w-14 h-14 rounded-xl bg-trail-peach flex items-center justify-center text-2xl shrink-0">
                        🎟️
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="font-bold text-trail-brown text-sm">{w.title}</p>
                        {w.description && (
                          <p className="text-xs text-gray-500 line-clamp-1 mt-0.5">{w.description}</p>
                        )}
                        <p className="text-xs text-gray-400 mt-1">
                          Issued {new Date(w.issued_at).toLocaleDateString()}
                        </p>
                      </div>
                      <div className="text-right shrink-0">
                        <button
                          onClick={() => copyCode(w.redemption_code)}
                          className="font-mono text-xs bg-trail-cream border border-trail-orange text-trail-brown px-3 py-1.5 rounded-lg hover:bg-trail-orange hover:text-white transition-all font-semibold"
                        >
                          {w.redemption_code}
                        </button>
                        <p className="text-[10px] text-gray-400 mt-1">tap to copy</p>
                        {w.status === 'redeemed' && (
                          <span className="text-[10px] text-gray-400">Used</span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )
            )}
          </div>
        </main>
      </div>
    </AuthGuard>
  );
}
