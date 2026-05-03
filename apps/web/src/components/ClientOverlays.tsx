'use client';

import { useEffect, useState } from 'react';
import { QrScannerModal } from './QrScannerModal';

function ConnectionBanner() {
  const [online, setOnline]           = useState(true);
  const [showRestored, setShowRestored] = useState(false);

  useEffect(() => {
    // Sync with actual browser state on mount
    setOnline(navigator.onLine);

    let restoreTimer: ReturnType<typeof setTimeout>;

    const handleOffline = () => {
      setOnline(false);
      setShowRestored(false);
    };

    const handleOnline = () => {
      setOnline(true);
      setShowRestored(true);
      restoreTimer = setTimeout(() => setShowRestored(false), 3000);
    };

    window.addEventListener('offline', handleOffline);
    window.addEventListener('online',  handleOnline);
    return () => {
      window.removeEventListener('offline', handleOffline);
      window.removeEventListener('online',  handleOnline);
      clearTimeout(restoreTimer);
    };
  }, []);

  if (online && !showRestored) return null;

  return (
    <div
      style={{ transition: 'transform 0.3s ease, opacity 0.3s ease' }}
      className={`fixed top-0 inset-x-0 z-[9999] flex items-center justify-center gap-2
                  py-2 px-4 text-xs font-semibold text-white shadow-md
                  ${!online
                    ? 'bg-red-500'
                    : 'bg-green-500'}`}
    >
      {!online ? (
        <>
          {/* No-wifi icon */}
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
               stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <line x1="1" y1="1" x2="23" y2="23" />
            <path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55" />
            <path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39" />
            <path d="M10.71 5.05A16 16 0 0 1 22.56 9" />
            <path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88" />
            <path d="M8.53 16.11a6 6 0 0 1 6.95 0" />
            <line x1="12" y1="20" x2="12.01" y2="20" />
          </svg>
          No internet connection
        </>
      ) : (
        <>
          {/* Checkmark icon */}
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
               stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <polyline points="20 6 9 17 4 12" />
          </svg>
          Connection restored
        </>
      )}
    </div>
  );
}

export default function ClientOverlays() {
  return (
    <>
      <ConnectionBanner />
      <QrScannerModal />
    </>
  );
}
