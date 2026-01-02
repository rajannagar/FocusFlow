import { Metadata } from 'next';
import { SITE_URL, SITE_NAME } from '@/lib/constants';

const siteUrl = SITE_URL;

export const metadata: Metadata = {
  title: 'Support & Contact - Get Help',
  description: 'Get support for FocusFlow and Soft Computers products. Find answers to frequently asked questions, contact us via email, or learn about account management.',
  keywords: [
    'FocusFlow support',
    'Soft Computers contact',
    'help',
    'FAQ',
    'customer support',
    'account help',
    'subscription help',
    'app support',
  ],
  openGraph: {
    title: 'Support & Contact - Soft Computers',
    description: 'Get support, ask questions, or share feedback. We typically respond within 24 hours.',
    url: `${siteUrl}/support`,
    siteName: 'Soft Computers',
    images: [
      {
        url: '/focusflow_app_icon.png',
        width: 512,
        height: 512,
        alt: 'Soft Computers Support',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary',
    title: 'Support & Contact - Soft Computers',
    description: 'Get support, ask questions, or share feedback. We typically respond within 24 hours.',
  },
  alternates: {
    canonical: `${siteUrl}/support`,
  },
};

export default function SupportLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}

