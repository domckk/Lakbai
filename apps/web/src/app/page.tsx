'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

export default function SplashPage() {
  const router = useRouter();
  const [showTagline, setShowTagline] = useState(false);
  const [exiting,     setExiting]     = useState(false);

  useEffect(() => {
    const dest = localStorage.getItem('access_token') ? '/dashboard' : '/login';
    // 0.4s delay → 1.4s write → 0.2s settle = tagline at 2.0s
    const t1 = setTimeout(() => setShowTagline(true), 2000);
    // start fade-out at 3.4s, navigate at 4.1s
    const t2 = setTimeout(() => setExiting(true),     3400);
    const t3 = setTimeout(() => router.push(dest),    4100);
    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3); };
  }, []);

  return (
    <>
      <style>{`
        @keyframes write-in {
          from { clip-path: inset(0 100% 0 0); }
          to   { clip-path: inset(0 0% 0 0); }
        }
        @keyframes pen-sweep {
          from { left: -2px;  opacity: 1; }
          95%  {              opacity: 1; }
          to   { left: 100%;  opacity: 0; }
        }
        @keyframes fade-up {
          from { opacity: 0; transform: translateY(8px); }
          to   { opacity: 1; transform: translateY(0);   }
        }
        @keyframes dot-pop {
          0%   { transform: scale(0); opacity: 0; }
          60%  { transform: scale(1.3); opacity: 1; }
          100% { transform: scale(1);   opacity: 1; }
        }
        @keyframes cursor-blink {
          0%, 100% { opacity: 1; }
          50%       { opacity: 0; }
        }
      `}</style>

      <main
        style={{
          minHeight: '100vh',
          background: '#FFFDF5',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 0,
          opacity: exiting ? 0 : 1,
          transition: 'opacity 0.7s cubic-bezier(0.4, 0, 0.2, 1)',
        }}
      >
        {/* Logo with write-in animation */}
        <div style={{ position: 'relative', display: 'inline-block' }}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/images/logo.png"
            alt="Lakbai"
            width={300}
            style={{
              display: 'block',
              background: 'transparent',
              animation: 'write-in 1.4s cubic-bezier(0.4, 0, 0.2, 1) 0.4s both',
            }}
          />

          {/* Pen cursor — vertical orange line that travels left→right */}
          <div
            style={{
              position: 'absolute',
              top: 0,
              bottom: 0,
              width: 3,
              borderRadius: 2,
              background: 'linear-gradient(to bottom, transparent 0%, #FF8C3B 30%, #FF8C3B 70%, transparent 100%)',
              boxShadow: '0 0 8px rgba(255,140,59,0.9)',
              animation: 'pen-sweep 1.4s cubic-bezier(0.4, 0, 0.2, 1) 0.4s both',
              pointerEvents: 'none',
            }}
          />
        </div>

        {/* Tagline + blinking cursor */}
        <div
          style={{
            marginTop: 28,
            minHeight: 32,
            display: 'flex',
            alignItems: 'center',
            gap: 6,
          }}
        >
          {showTagline && (
            <>
              <p
                style={{
                  margin: 0,
                  color: '#3D2000',
                  fontSize: 10,
                  letterSpacing: '0.22em',
                  textTransform: 'uppercase',
                  fontWeight: 600,
                  opacity: 0.45,
                  animation: 'fade-up 0.5s ease both',
                }}
              >
                Gamified Digital Tourism Platform
              </p>
              <div
                style={{
                  width: 2,
                  height: 14,
                  background: '#FF8C3B',
                  borderRadius: 1,
                  animation: 'cursor-blink 0.9s step-end infinite',
                  opacity: 0.7,
                }}
              />
            </>
          )}
        </div>

        {/* Dot that pops in after write finishes */}
        {showTagline && (
          <div
            style={{
              position: 'fixed',
              bottom: 48,
              left: '50%',
              transform: 'translateX(-50%)',
              display: 'flex',
              gap: 6,
            }}
          >
            {[0, 1, 2].map((i) => (
              <div
                key={i}
                style={{
                  width: 6,
                  height: 6,
                  borderRadius: '50%',
                  background: '#FF8C3B',
                  opacity: 0.4,
                  animation: `dot-pop 0.4s ease ${i * 0.12}s both`,
                }}
              />
            ))}
          </div>
        )}
      </main>
    </>
  );
}
