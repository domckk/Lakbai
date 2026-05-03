'use client';

import { useEffect, useRef, useState } from 'react';
import { useStore } from '@/lib/store';
import { apiClient } from '@/lib/api-client';

type Phase = 'scanning' | 'submitting' | 'result' | 'error';

type CheckInResult = {
  valid: boolean;
  reason?: string;
  xp_awarded?: number;
  stamp?: { name: string; rarity: string };
  level_up?: { from: number; to: number };
  badges_unlocked?: Array<{ id: string; name: string; icon: string }>;
  quest_complete?: boolean;
  next_checkpoint?: { id: string; title: string };
};

export function QrScannerModal() {
  const { qrScannerOpen, setQrScannerOpen } = useStore();
  const [phase, setPhase]   = useState<Phase>('scanning');
  const [result, setResult] = useState<CheckInResult | null>(null);
  const [errMsg, setErrMsg] = useState('');
  const scannerRef = useRef<any>(null);
  const activeRef  = useRef(false);

  useEffect(() => {
    if (!qrScannerOpen) return;

    activeRef.current = true;
    setPhase('scanning');
    setResult(null);
    setErrMsg('');

    (async () => {
      try {
        const { Html5Qrcode } = await import('html5-qrcode');
        if (!activeRef.current) return;

        const scanner = new Html5Qrcode('qr-scanner-view');
        scannerRef.current = scanner;

        await scanner.start(
          { facingMode: 'environment' },
          { fps: 10, qrbox: { width: 250, height: 250 } },
          async (decoded: string) => {
            await scanner.stop().catch(() => {});
            scannerRef.current = null;
            if (activeRef.current) handleDecoded(decoded);
          },
          undefined,
        );
      } catch {
        if (activeRef.current) {
          setErrMsg('Camera access denied. Please allow camera permission and try again.');
          setPhase('error');
        }
      }
    })();

    return () => {
      activeRef.current = false;
      scannerRef.current?.stop().catch(() => {});
      scannerRef.current = null;
    };
  }, [qrScannerOpen]);

  const handleDecoded = async (text: string) => {
    setPhase('submitting');

    let checkpointId: string | null = null;
    let token: string | null = null;

    try {
      const data = JSON.parse(text);
      checkpointId = data.cp ?? null;
      token        = data.t  ?? null;
    } catch {
      setErrMsg('Not a valid Lakbai QR code. Please scan a checkpoint sign.');
      setPhase('error');
      return;
    }

    if (!checkpointId || !token) {
      setErrMsg('QR code is missing required checkpoint data.');
      setPhase('error');
      return;
    }

    const pos = await new Promise<GeolocationPosition | null>((resolve) =>
      navigator.geolocation.getCurrentPosition(resolve, () => resolve(null), {
        timeout: 5000,
        enableHighAccuracy: true,
      }),
    );

    try {
      const res = await apiClient.post(`/checkpoints/${checkpointId}/checkin`, {
        lat:       pos?.coords.latitude  ?? 0,
        lng:       pos?.coords.longitude ?? 0,
        accuracy_m: pos?.coords.accuracy ?? 999,
        qr_token:  token,
        client_ts: new Date().toISOString(),
      });
      setResult(res.data);
      setPhase('result');
    } catch (e: any) {
      setErrMsg(e.response?.data?.message ?? 'Check-in failed. Please try again.');
      setPhase('error');
    }
  };

  const close = async () => {
    activeRef.current = false;
    await scannerRef.current?.stop().catch(() => {});
    scannerRef.current = null;
    setQrScannerOpen(false);
  };

  if (!qrScannerOpen) return null;

  return (
    <div
      className="fixed inset-0 z-[100] bg-black flex flex-col"
      style={{ paddingTop: 'env(safe-area-inset-top, 0px)' }}
    >
      {/* ── Header ── */}
      <div className="flex items-center justify-between px-4 py-4 shrink-0">
        <h2 className="text-white font-bold text-lg">Scan Checkpoint</h2>
        <button
          onClick={close}
          className="w-9 h-9 rounded-full bg-white/10 flex items-center justify-center text-white text-xl font-bold hover:bg-white/20 transition-colors"
          aria-label="Close scanner"
        >
          ×
        </button>
      </div>

      {/* ── Camera view (only mounted during scanning so html5-qrcode can find the element) ── */}
      {phase === 'scanning' && (
        <>
          <div id="qr-scanner-view" className="flex-1 overflow-hidden" />
          <div
            className="shrink-0 px-6 py-5 text-center"
            style={{ paddingBottom: 'env(safe-area-inset-bottom, 20px)' }}
          >
            <p className="text-white/60 text-sm">
              Point your camera at a Lakbai checkpoint QR code
            </p>
          </div>
        </>
      )}

      {/* ── Submitting ── */}
      {phase === 'submitting' && (
        <div className="flex-1 flex flex-col items-center justify-center gap-4 px-6">
          <div className="w-16 h-16 rounded-full border-4 border-trail-orange border-t-transparent animate-spin" />
          <p className="text-white font-semibold text-lg">Checking in…</p>
          <p className="text-white/40 text-sm">Getting your location</p>
        </div>
      )}

      {/* ── Result ── */}
      {phase === 'result' && result && (
        <div
          className="flex-1 flex flex-col items-center justify-center px-6 text-center gap-4 overflow-y-auto"
          style={{ paddingBottom: 'env(safe-area-inset-bottom, 20px)' }}
        >
          {result.valid ? (
            <>
              <div className="w-24 h-24 rounded-full bg-green-500 flex items-center justify-center shadow-lg shadow-green-500/30">
                <span className="text-white text-5xl leading-none">✓</span>
              </div>
              <h3 className="text-white text-2xl font-bold">Checked In!</h3>

              {result.xp_awarded != null && (
                <div className="bg-trail-orange/20 border border-trail-orange/30 rounded-2xl px-6 py-2">
                  <p className="text-trail-orange text-3xl font-bold">+{result.xp_awarded} XP</p>
                </div>
              )}

              {result.level_up && (
                <div className="bg-yellow-400/20 border border-yellow-400/30 rounded-xl px-5 py-2.5 w-full max-w-xs">
                  <p className="text-yellow-300 font-bold">🎉 Level Up! → Level {result.level_up.to}</p>
                </div>
              )}

              {result.stamp && (
                <p className="text-white/70 text-sm">
                  Stamp earned:{' '}
                  <span className="text-white font-semibold">{result.stamp.name}</span>
                </p>
              )}

              {result.badges_unlocked && result.badges_unlocked.length > 0 && (
                <div className="bg-purple-500/20 border border-purple-400/30 rounded-xl px-5 py-2.5 w-full max-w-xs">
                  <p className="text-purple-300 font-medium">
                    {result.badges_unlocked[0]?.icon} Badge: {result.badges_unlocked[0]?.name}
                  </p>
                </div>
              )}

              {result.quest_complete && (
                <div className="bg-green-500/20 border border-green-400/30 rounded-xl px-5 py-2.5 w-full max-w-xs">
                  <p className="text-green-300 font-semibold">🏆 Quest Complete!</p>
                </div>
              )}

              {result.next_checkpoint && (
                <p className="text-white/40 text-xs mt-1">
                  Next: {result.next_checkpoint.title}
                </p>
              )}
            </>
          ) : (
            <>
              <div className="w-24 h-24 rounded-full bg-red-500/20 border border-red-400/30 flex items-center justify-center">
                <span className="text-red-400 text-5xl leading-none">✗</span>
              </div>
              <h3 className="text-white text-2xl font-bold">Check-in Failed</h3>
              <p className="text-white/60 text-sm max-w-xs leading-relaxed">
                {result.reason === 'OUT_OF_RANGE'    ? "You're too far from this checkpoint. Get closer and try again." :
                 result.reason === 'QR_INVALID'      ? 'This QR code has expired. Ask for a refreshed one.' :
                 result.reason === 'QR_REQUIRED'     ? 'QR token is required for this checkpoint.' :
                 result.reason === 'ALREADY_VISITED' ? "You've already checked in here." :
                 result.reason ?? 'Unknown error.'}
              </p>
            </>
          )}

          <button
            onClick={close}
            className="mt-4 bg-trail-orange text-white px-10 py-3.5 rounded-2xl font-bold text-base active:scale-95 transition-transform"
          >
            Done
          </button>
        </div>
      )}

      {/* ── Error ── */}
      {phase === 'error' && (
        <div
          className="flex-1 flex flex-col items-center justify-center px-6 text-center gap-4"
          style={{ paddingBottom: 'env(safe-area-inset-bottom, 20px)' }}
        >
          <span className="text-6xl">📷</span>
          <h3 className="text-white text-xl font-bold">Couldn&apos;t Scan</h3>
          <p className="text-white/60 text-sm max-w-xs leading-relaxed">{errMsg}</p>
          <button
            onClick={close}
            className="mt-2 bg-trail-orange text-white px-8 py-3.5 rounded-2xl font-bold active:scale-95 transition-transform"
          >
            Close
          </button>
        </div>
      )}
    </div>
  );
}
