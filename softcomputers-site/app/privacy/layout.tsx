import { Metadata } from 'next';

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://softcomputers.ca';

export const metadata: Metadata = {
  title: 'Privacy Policy',
  description: 'Privacy Policy for FocusFlow and Soft Computers. Learn how we handle your data, our privacy-first approach, Guest Mode, and your rights regarding data access and deletion.',
  keywords: [
    'privacy policy',
    'FocusFlow privacy',
    'data privacy',
    'GDPR',
    'privacy-first',
    'data protection',
    'guest mode',
    'no tracking',
  ],
  openGraph: {
    title: 'Privacy Policy - Soft Computers',
    description: 'Learn how FocusFlow handles your data. Privacy-first approach with Guest Mode, no tracking, and no ads.',
    url: `${siteUrl}/privacy`,
    siteName: 'Soft Computers',
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary',
    title: 'Privacy Policy - Soft Computers',
    description: 'Learn how FocusFlow handles your data. Privacy-first approach with Guest Mode, no tracking, and no ads.',
  },
  alternates: {
    canonical: `${siteUrl}/privacy`,
  },
};

export default function PrivacyLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}

