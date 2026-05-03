import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import dynamic from 'next/dynamic';
import '@/app/globals.css';

const inter = Inter({ subsets: ['latin'] });

const ClientOverlays = dynamic(() => import('@/components/ClientOverlays'), { ssr: false });

export const metadata: Metadata = {
  title: 'Lakbai',
  description: 'Gamified tourism platform — explore, scan, earn.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>
        {children}
        <ClientOverlays />
      </body>
    </html>
  );
}
