import { Metadata } from 'next';

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://www.softcomputers.ca';

export const metadata: Metadata = {
  title: 'Terms of Service',
  description: 'Terms of Service for FocusFlow and Soft Computers. Learn about account terms, FocusFlow Pro subscription, acceptable use, and your rights.',
  keywords: [
    'terms of service',
    'terms and conditions',
    'FocusFlow terms',
    'subscription terms',
    'user agreement',
    'legal',
  ],
  openGraph: {
    title: 'Terms of Service - Soft Computers',
    description: 'Terms of Service for FocusFlow. Learn about subscriptions, acceptable use, and user rights.',
    url: `${siteUrl}/terms`,
    siteName: 'Soft Computers',
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary',
    title: 'Terms of Service - Soft Computers',
    description: 'Terms of Service for FocusFlow. Learn about subscriptions, acceptable use, and user rights.',
  },
  alternates: {
    canonical: `${siteUrl}/terms`,
  },
};

export default function TermsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}

