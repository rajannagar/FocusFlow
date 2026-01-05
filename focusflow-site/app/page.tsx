import { Metadata } from 'next';
import { generatePageMetadata, generateBreadcrumbSchema } from '@/lib/seo';
import HomeClient from './HomeClient';

// Page metadata
export const metadata: Metadata = generatePageMetadata({
  title: 'FocusFlow - Be Present',
  description: 'The all-in-one focus timer, task manager, and progress tracker. Beautiful, private, and built for deep work. Download for iOS.',
  path: '/',
  keywords: [
    'focus timer',
    'productivity app',
    'task manager',
    'iOS app',
    'focus app',
    'pomodoro timer',
    'habit tracker',
    'time management',
    'deep work',
    'concentration app',
    'FocusFlow',
  ],
});

// Breadcrumb structured data
const breadcrumbSchema = generateBreadcrumbSchema([
  { name: 'Home', url: '/' },
]);

export default function Home() {
  return (
    <>
      {/* Structured Data */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <HomeClient />
    </>
  );
}
