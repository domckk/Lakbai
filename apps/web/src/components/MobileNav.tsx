'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useStore } from '@/lib/store';
import { IconHome, IconQuests, IconPassports, IconProfile } from '@/components/icons';
import type { ComponentType } from 'react';

interface NavItemDef { href: string; Icon: ComponentType<{ className?: string; size?: number }>; label: string; }

const LEFT_ITEMS: NavItemDef[] = [
  { href: '/dashboard', Icon: IconHome,      label: 'Home'     },
  { href: '/quests',    Icon: IconQuests,    label: 'Quests'   },
];
const RIGHT_ITEMS: NavItemDef[] = [
  { href: '/passports', Icon: IconPassports, label: 'Passport' },
  { href: '/profile',   Icon: IconProfile,   label: 'Profile'  },
];

export function MobileNav() {
  const pathname = usePathname();
  const { setQrScannerOpen } = useStore();

  const NavLink = ({ href, Icon, label }: NavItemDef) => {
    const active = pathname === href || pathname.startsWith(href + '/');
    return (
      <Link
        href={href}
        className={`flex flex-col items-center gap-0.5 py-2 px-3 rounded-xl transition-colors min-w-[56px]
                    ${active ? 'text-trail-orange' : 'text-gray-400 active:text-trail-brown'}`}
      >
        <Icon size={22} />
        <span className={`text-[10px] font-medium leading-tight ${active ? 'text-trail-orange' : ''}`}>
          {label}
        </span>
      </Link>
    );
  };

  return (
    <nav
      className="md:hidden fixed bottom-0 inset-x-0 z-50 bg-white border-t border-gray-100"
      style={{ paddingBottom: 'env(safe-area-inset-bottom, 10px)' }}
    >
      <div className="relative flex items-center justify-around px-1">
        {LEFT_ITEMS.map((item) => <NavLink key={item.href} {...item} />)}

        {/* Centre QR scan button — elevated above nav bar */}
        <div className="flex flex-col items-center -mt-5 px-3">
          <button
            onClick={() => setQrScannerOpen(true)}
            className="w-14 h-14 rounded-full bg-trail-orange flex items-center justify-center
                       shadow-lg border-4 border-white active:scale-95 transition-transform"
            aria-label="Scan QR checkpoint"
          >
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              {/* Top-left finder pattern */}
              <rect x="2" y="2" width="8" height="8" rx="1.2" fill="white"/>
              <rect x="3.5" y="3.5" width="5" height="5" rx="0.6" fill="#f97316"/>
              <rect x="5" y="5" width="2" height="2" fill="white"/>
              {/* Top-right finder pattern */}
              <rect x="14" y="2" width="8" height="8" rx="1.2" fill="white"/>
              <rect x="15.5" y="3.5" width="5" height="5" rx="0.6" fill="#f97316"/>
              <rect x="17" y="5" width="2" height="2" fill="white"/>
              {/* Bottom-left finder pattern */}
              <rect x="2" y="14" width="8" height="8" rx="1.2" fill="white"/>
              <rect x="3.5" y="15.5" width="5" height="5" rx="0.6" fill="#f97316"/>
              <rect x="5" y="17" width="2" height="2" fill="white"/>
              {/* Data dots bottom-right */}
              <rect x="14" y="14" width="2" height="2" rx="0.3" fill="white"/>
              <rect x="17" y="14" width="2" height="2" rx="0.3" fill="white"/>
              <rect x="20" y="14" width="2" height="2" rx="0.3" fill="white"/>
              <rect x="14" y="17" width="2" height="2" rx="0.3" fill="white"/>
              <rect x="20" y="17" width="2" height="2" rx="0.3" fill="white"/>
              <rect x="17" y="20" width="2" height="2" rx="0.3" fill="white"/>
              <rect x="20" y="20" width="2" height="2" rx="0.3" fill="white"/>
            </svg>
          </button>
          <span className="text-[10px] font-medium mt-0.5 leading-tight text-gray-400">
            Scan
          </span>
        </div>

        {RIGHT_ITEMS.map((item) => <NavLink key={item.href} {...item} />)}
      </div>
    </nav>
  );
}
