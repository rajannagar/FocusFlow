import { Metadata } from 'next';
import { generatePageMetadata, generateBreadcrumbSchema } from '@/lib/seo';
import PrivacyClient from './PrivacyClient';

// Page metadata
export const metadata: Metadata = generatePageMetadata({
  title: 'Privacy Policy',
  description: 'FocusFlow Privacy Policy. Learn how we protect your data, what we collect, and your privacy rights. Privacy-first productivity app.',
  path: '/privacy/',
  keywords: [
    'FocusFlow privacy',
    'privacy policy',
    'data protection',
    'user privacy',
    'GDPR',
    'data security',
  ],
});

// Breadcrumb structured data
const breadcrumbSchema = generateBreadcrumbSchema([
  { name: 'Home', url: '/' },
  { name: 'Privacy Policy', url: '/privacy/' },
]);

export default function PrivacyPage() {
  return (
    <>
      {/* Structured Data */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <PrivacyClient />
    </>
  );
}
