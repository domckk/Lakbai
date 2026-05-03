'use client';

import { useRouter } from 'next/navigation';

interface Props {
  title: string;
  subtitle?: string;
  right?: React.ReactNode;
}

export function PageHeader({ title, subtitle, right }: Props) {
  const router = useRouter();

  return (
    <div className="bg-white border-b border-gray-100 px-4 md:px-8 py-3 md:py-4 sticky top-0 z-40">
      <div className="flex items-center gap-3">
        {/* Back button */}
        <button
          onClick={() => router.back()}
          aria-label="Go back"
          className="flex items-center justify-center w-9 h-9 rounded-xl shrink-0
                     bg-gray-100 hover:bg-gray-200 text-trail-brown
                     transition-colors active:scale-95"
        >
          <span className="text-lg leading-none">←</span>
        </button>

        {/* Title block */}
        <div className="flex-1 min-w-0">
          <h1 className="text-base md:text-xl font-bold text-trail-brown leading-tight truncate">
            {title}
          </h1>
          {subtitle && (
            <p className="text-xs text-gray-400 mt-0.5 hidden sm:block truncate">{subtitle}</p>
          )}
        </div>

        {/* Optional right-side controls */}
        {right && <div className="shrink-0 flex items-center gap-2">{right}</div>}
      </div>
    </div>
  );
}
