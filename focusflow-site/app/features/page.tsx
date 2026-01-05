import { Metadata } from 'next';
import { generatePageMetadata, generateBreadcrumbSchema } from '@/lib/seo';
import FeaturesClient from './FeaturesClient';

// Page metadata
export const metadata: Metadata = generatePageMetadata({
  title: 'Features',
  description: 'Discover FocusFlow features: focus timer with 14 ambient backgrounds, smart task management, progress tracking with XP system, cloud sync, and more.',
  path: '/features/',
  keywords: [
    'FocusFlow features',
    'focus timer features',
    'task manager features',
    'productivity app features',
    'focus app capabilities',
    'XP system',
    'cloud sync',
    'ambient backgrounds',
    'focus sounds',
  ],
});

// Breadcrumb structured data
const breadcrumbSchema = generateBreadcrumbSchema([
  { name: 'Home', url: '/' },
  { name: 'Features', url: '/features/' },
]);

export default function FeaturesPage() {
  return (
    <>
      {/* Structured Data */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <FeaturesClient />
    </>
  );
}
