import { Metadata } from 'next';
import { generatePageMetadata, generateProductSchema, generateFAQSchema } from '@/lib/seo';
import PricingClient from './PricingClient';

// Page metadata
export const metadata: Metadata = generatePageMetadata({
  title: 'FocusFlow Pro Pricing',
  description: 'Choose your FocusFlow Pro plan. Start free, upgrade when ready. Monthly and yearly subscriptions available with all premium features.',
  path: '/pricing/',
  keywords: [
    'FocusFlow Pro pricing',
    'focus app subscription',
    'productivity app cost',
    'FocusFlow Pro plans',
    'focus timer premium',
    'task manager subscription',
  ],
  type: 'website',
});

// FAQ structured data
const faqSchema = generateFAQSchema([
  {
    question: 'Is there a free trial?',
    answer: 'Yes! All Pro features are available with a free trial. You can cancel anytime during the trial period.',
  },
  {
    question: 'Can I switch between monthly and yearly?',
    answer: 'Yes, you can change your subscription plan at any time from your account settings.',
  },
  {
    question: 'What happens if I cancel?',
    answer: "You'll keep access to Pro features until the end of your billing period. After that, you'll revert to the Free plan.",
  },
  {
    question: 'Do I need to sign in for Pro?',
    answer: 'Yes, Pro features require an account for cloud sync and cross-device access. The Free plan works offline without an account.',
  },
  {
    question: 'Can I use Pro on multiple devices?',
    answer: 'Yes! With Pro, you can sign in and sync your data across all your devices (iOS, Web, macOS).',
  },
]);

// Product structured data
const productSchema = generateProductSchema();

export default function PricingPage() {
  return (
    <>
      {/* Structured Data */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(productSchema) }}
      />
      <PricingClient />
    </>
  );
}
