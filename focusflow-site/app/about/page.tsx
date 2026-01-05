import { Metadata } from 'next';
import { generatePageMetadata, generateBreadcrumbSchema } from '@/lib/seo';
import AboutClient from './AboutClient';

// Page metadata
export const metadata: Metadata = generatePageMetadata({
  title: 'About Us',
  description: 'Learn about FocusFlow and Soft Computers. Built with intention, designed for deep work. Privacy-first productivity app for iOS.',
  path: '/about/',
  keywords: [
    'FocusFlow about',
    'Soft Computers',
    'productivity app developer',
    'focus app company',
    'privacy-first apps',
    'iOS app developer',
  ],
});

// Breadcrumb structured data
const breadcrumbSchema = generateBreadcrumbSchema([
  { name: 'Home', url: '/' },
  { name: 'About', url: '/about/' },
]);

export default function AboutPage() {
  return (
    <>
      {/* Structured Data */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <AboutClient />
    </>
  );
}
