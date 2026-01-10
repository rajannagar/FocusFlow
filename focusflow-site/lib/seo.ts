/**
 * SEO utility functions and metadata generators
 */

import { Metadata } from 'next';
import { SITE_URL, SITE_NAME, SITE_DESCRIPTION, CONTACT_EMAIL, APP_STORE_URL } from './constants';

export interface PageSEOProps {
  title: string;
  description: string;
  path: string;
  keywords?: string[];
  image?: string;
  noindex?: boolean;
  type?: 'website' | 'article';
}

/**
 * Generate comprehensive metadata for a page
 */
export function generatePageMetadata({
  title,
  description,
  path,
  keywords = [],
  image = '/focusflow-app-icon.jpg',
  noindex = false,
  type = 'website',
}: PageSEOProps): Metadata {
  const url = `${SITE_URL}${path}`;
  const fullTitle = `${title} | ${SITE_NAME}`;
  const imageUrl = image.startsWith('http') ? image : `${SITE_URL}${image}`;

  return {
    title: fullTitle,
    description,
    keywords: keywords.length > 0 ? keywords : undefined,
    alternates: {
      canonical: url,
    },
    openGraph: {
      title: fullTitle,
      description,
      url,
      siteName: SITE_NAME,
      images: [
        {
          url: imageUrl,
          width: 1200,
          height: 630,
          alt: title,
        },
      ],
      locale: 'en_US',
      type,
    },
    twitter: {
      card: 'summary_large_image',
      title: fullTitle,
      description,
      images: [imageUrl],
      creator: '@focusflow',
    },
    robots: {
      index: !noindex,
      follow: !noindex,
      googleBot: {
        index: !noindex,
        follow: !noindex,
        'max-video-preview': -1,
        'max-image-preview': 'large',
        'max-snippet': -1,
      },
    },
  };
}

/**
 * Generate FAQ structured data (JSON-LD)
 */
export function generateFAQSchema(faqs: Array<{ question: string; answer: string }>) {
  return {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: faqs.map((faq) => ({
      '@type': 'Question',
      name: faq.question,
      acceptedAnswer: {
        '@type': 'Answer',
        text: faq.answer,
      },
    })),
  };
}

/**
 * Generate breadcrumb structured data (JSON-LD)
 */
export function generateBreadcrumbSchema(items: Array<{ name: string; url: string }>) {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.name,
      item: item.url.startsWith('http') ? item.url : `${SITE_URL}${item.url}`,
    })),
  };
}

/**
 * Generate product structured data (JSON-LD) for pricing page
 */
export function generateProductSchema() {
  return {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: 'FocusFlow Pro',
    applicationCategory: 'ProductivityApplication',
    operatingSystem: 'iOS',
    offers: [
      {
        '@type': 'Offer',
        name: 'FocusFlow Pro Monthly',
        price: '5.99',
        priceCurrency: 'USD',
        availability: 'https://schema.org/InStock',
        url: APP_STORE_URL || SITE_URL,
      },
      {
        '@type': 'Offer',
        name: 'FocusFlow Pro Yearly',
        price: '59.99',
        priceCurrency: 'USD',
        availability: 'https://schema.org/InStock',
        url: APP_STORE_URL || SITE_URL,
      },
    ],
    description: SITE_DESCRIPTION,
    image: `${SITE_URL}/focusflow-app-icon.jpg`,
    author: {
      '@type': 'Organization',
      name: SITE_NAME,
      email: CONTACT_EMAIL,
    },
    downloadUrl: APP_STORE_URL || SITE_URL,
  };
}

/**
 * Generate SoftwareApplication schema for the app page (coming soon state)
 */
export function generateSoftwareAppSchema() {
  return {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: 'FocusFlow',
    operatingSystem: 'iOS',
    applicationCategory: 'ProductivityApplication',
    description: SITE_DESCRIPTION,
    url: SITE_URL,
    image: `${SITE_URL}/focusflow_app_icon.png`,
    publisher: {
      '@type': 'Organization',
      name: SITE_NAME,
      url: SITE_URL,
    },
    offers: {
      '@type': 'Offer',
      price: '5.99',
      priceCurrency: 'USD',
      availability: 'https://schema.org/InStock',
      url: APP_STORE_URL || SITE_URL,
    },
  };
}

/**
 * Generate organization structured data (JSON-LD)
 */
export function generateOrganizationSchema() {
  return {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: SITE_NAME,
    url: SITE_URL,
    logo: `${SITE_URL}/focusflow-logo.png`,
    description: SITE_DESCRIPTION,
    email: CONTACT_EMAIL,
    address: {
      '@type': 'PostalAddress',
      addressLocality: 'Toronto',
      addressRegion: 'Ontario',
      addressCountry: 'CA',
    },
    sameAs: [],
  };
}
