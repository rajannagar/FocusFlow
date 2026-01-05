import { Metadata } from 'next';
import { generatePageMetadata, generateBreadcrumbSchema } from '@/lib/seo';
import TermsClient from './TermsClient';

// Page metadata
export const metadata: Metadata = generatePageMetadata({
  title: 'Terms of Service',
  description: 'FocusFlow Terms of Service. Read our terms and conditions for using FocusFlow, including subscription terms, user rights, and acceptable use.',
  path: '/terms/',
  keywords: [
    'FocusFlow terms',
    'terms of service',
    'user agreement',
    'subscription terms',
    'legal terms',
  ],
});

// Breadcrumb structured data
const breadcrumbSchema = generateBreadcrumbSchema([
  { name: 'Home', url: '/' },
  { name: 'Terms of Service', url: '/terms/' },
]);

export default function TermsPage() {
  return (
    <>
      {/* Structured Data */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <TermsClient />
    </>
  );
}
