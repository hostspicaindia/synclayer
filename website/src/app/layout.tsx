import type { Metadata } from 'next';
import './globals.css';
import Navigation from '@/components/Navigation';
import Footer from '@/components/Footer';
import Analytics from '@/components/Analytics';
import KeyboardShortcuts from '@/components/KeyboardShortcuts';
import SkipToContent from '@/components/SkipToContent';
import PerformanceMonitor from '@/components/PerformanceMonitor';

export const metadata: Metadata = {
  title: {
    default: 'HostSpica SDK - Enterprise-Grade SDKs for Modern Development',
    template: '%s | HostSpica SDK'
  },
  description: 'Production-ready software development kits for Flutter, JavaScript, Python, and more. Save months of development time with battle-tested, well-documented libraries.',
  keywords: ['SDK', 'Flutter', 'JavaScript', 'Python', 'Go', 'Rust', '.NET', 'SyncLayer', 'offline-first', 'local-first', 'open source'],
  authors: [{ name: 'HostSpica', url: 'https://hostspica.com' }],
  creator: 'HostSpica',
  publisher: 'HostSpica',
  metadataBase: new URL('https://sdk.hostspica.com'),
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://sdk.hostspica.com',
    siteName: 'HostSpica SDK',
    title: 'HostSpica SDK - Enterprise-Grade SDKs for Modern Development',
    description: 'Production-ready software development kits for Flutter, JavaScript, Python, and more.',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'HostSpica SDK Platform'
      }
    ]
  },
  twitter: {
    card: 'summary_large_image',
    site: '@hostspicaindia',
    creator: '@hostspicaindia',
    title: 'HostSpica SDK - Enterprise-Grade SDKs for Modern Development',
    description: 'Production-ready software development kits for Flutter, JavaScript, Python, and more.',
    images: ['/og-image.png']
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  icons: {
    icon: '/logo.png',
    apple: '/logo.png',
  },
  manifest: '/manifest.json',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <SkipToContent />
        <Analytics />
        <KeyboardShortcuts />
        <PerformanceMonitor />
        <Navigation />
        <main id="main-content">
          {children}
        </main>
        <Footer />
      </body>
    </html>
  );
}
