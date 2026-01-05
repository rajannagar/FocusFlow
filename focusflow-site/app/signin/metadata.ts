import { generatePageMetadata } from '@/lib/seo';

export const metadata = generatePageMetadata({
  title: 'Sign In',
  description: 'Sign in to FocusFlow to access your account and sync your data across devices.',
  path: '/signin/',
  keywords: [
    'FocusFlow sign in',
    'FocusFlow login',
    'FocusFlow account',
  ],
  noindex: true, // Utility/auth page – keep out of search results
});
