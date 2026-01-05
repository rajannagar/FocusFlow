import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Only use static export in production builds
  ...(process.env.NODE_ENV === 'production' && {
  output: 'export', // Generate static HTML files for AWS Amplify
  images: {
    unoptimized: true, // Required for static export
  },
  }),
  // In development, use dynamic features
  ...(process.env.NODE_ENV === 'development' && {
    images: {
      domains: [],
    },
  }),
  trailingSlash: true, // Add trailing slashes to URLs
  // Performance optimizations
  compress: true,
  poweredByHeader: false,
  reactStrictMode: true,
};

export default nextConfig;
