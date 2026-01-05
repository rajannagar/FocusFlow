import { Metadata } from 'next';
import { generatePageMetadata, generateBreadcrumbSchema } from '@/lib/seo';
import WebAppClient from './WebAppClient';

// Page metadata
export const metadata: Metadata = generatePageMetadata({
  title: 'Web App Coming Soon',
  description: 'FocusFlow web app is coming soon. Sign in to get notified when the web app launches. Access your sessions, tasks, and progress from any browser.',
  path: '/webapp/',
  keywords: [
    'FocusFlow web app',
    'FocusFlow desktop',
    'web version',
    'coming soon',
    'sign in',
    'notify me',
  ],
  noindex: true, // Coming soon page, don't index yet
});

// Breadcrumb structured data
const breadcrumbSchema = generateBreadcrumbSchema([
  { name: 'Home', url: '/' },
  { name: 'Web App', url: '/webapp/' },
]);

export default function WebAppPage() {
  return (
    <>
      {/* Structured Data */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <WebAppClient />
    </>
  );
}
