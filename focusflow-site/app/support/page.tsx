import { Metadata } from 'next';
import { generatePageMetadata, generateFAQSchema, generateBreadcrumbSchema } from '@/lib/seo';
import { CONTACT_EMAIL } from '@/lib/constants';
import SupportClient from './SupportClient';

// Page metadata
export const metadata: Metadata = generatePageMetadata({
  title: 'Support & Contact',
  description: 'Get help with FocusFlow. Find answers to frequently asked questions, contact support, and learn how to sync data, cancel subscriptions, and more.',
  path: '/support/',
  keywords: [
    'FocusFlow support',
    'FocusFlow help',
    'contact FocusFlow',
    'FAQ',
    'troubleshooting',
    'account help',
    'subscription help',
  ],
});

// FAQ structured data
const faqSchema = generateFAQSchema([
  {
    question: 'How do I sync my data across devices?',
    answer: 'Sign in with your Apple, Google, or email account to enable cloud sync. Your sessions, tasks, presets, and settings will automatically sync across all your devices.',
  },
  {
    question: 'Can I use FocusFlow without an account?',
    answer: 'Yes! Guest Mode allows you to use FocusFlow with all features except cloud sync. All your data stays on your device.',
  },
  {
    question: 'How do I cancel my FocusFlow Pro subscription?',
    answer: 'Cancel anytime through your Apple ID settings. Go to Settings → [Your Name] → Subscriptions, find FocusFlow Pro, and tap Cancel Subscription.',
  },
  {
    question: 'How do I delete my account?',
    answer: 'Go to Profile → Settings → Delete Account. Confirm by typing "DELETE". All your data will be permanently removed from our servers.',
  },
  {
    question: 'Does FocusFlow work offline?',
    answer: "Yes! Focus sessions and tasks work without an internet connection. Your data syncs automatically when you're back online.",
  },
  {
    question: 'How do I restore my Pro subscription?',
    answer: 'If you previously had FocusFlow Pro, you can restore it by going to Profile → Settings → Restore Purchases. This will reactivate your subscription if it\'s still valid.',
  },
  {
    question: 'Can I export my data?',
    answer: 'Yes! Go to Profile → Settings → Backup & Export to download a JSON file with all your data. This is useful for backup or moving to a new device.',
  },
  {
    question: 'What if I have a feature request?',
    answer: `We love hearing from you! Email us at ${CONTACT_EMAIL} with your ideas. We review all feedback and consider it for future updates.`,
  },
]);

// Breadcrumb structured data
const breadcrumbSchema = generateBreadcrumbSchema([
  { name: 'Home', url: '/' },
  { name: 'Support', url: '/support/' },
]);

export default function SupportPage() {
  return (
    <>
      {/* Structured Data */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <SupportClient />
    </>
  );
}
