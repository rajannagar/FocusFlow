import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export', // Static export for Amplify
  images: {
    unoptimized: true, // Required for static export
  },
  trailingSlash: true, // Add trailing slashes to URLs
  compress: true,
  poweredByHeader: false,
  reactStrictMode: true,
};

export default nextConfig;
