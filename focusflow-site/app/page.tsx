import { Metadata } from 'next';
import { generatePageMetadata, generateBreadcrumbSchema } from '@/lib/seo';
import HomeClient from './HomeClient';

// Page metadata - Homepage uses default title without template
export const metadata: Metadata = {
  title: 'FocusFlow - Be Present | Focus Timer & Productivity App',
  description: 'FocusFlow is the all-in-one focus timer, task manager, and progress tracker. Beautiful, private, and built for deep work. Available on iOS.',
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
  alternates: {
    canonical: 'https://focusflowbepresent.com/',
  },
  openGraph: {
    title: 'FocusFlow - Be Present | Focus Timer & Productivity App',
    description: 'FocusFlow is the all-in-one focus timer, task manager, and progress tracker. Beautiful, private, and built for deep work. Available on iOS.',
    url: 'https://focusflowbepresent.com/',
    siteName: 'FocusFlow',
    images: [
      {
        url: '/focusflow_app_icon.png',
        width: 512,
        height: 512,
        alt: 'FocusFlow - Be Present',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'FocusFlow - Be Present | Focus Timer & Productivity App',
    description: 'FocusFlow is the all-in-one focus timer, task manager, and progress tracker. Beautiful, private, and built for deep work. Available on iOS.',
    images: ['/focusflow_app_icon.png'],
    creator: '@focusflow',
  },
};

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
