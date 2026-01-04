import type { Metadata } from "next";
import { Sora, Inter } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/contexts/AuthContext";

// Premium Display Font - Geometric, Modern
const sora = Sora({
  variable: "--font-clash",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  display: "swap",
});

// Body Font - Clean, Readable
const inter = Inter({
  variable: "--font-cabinet",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://webapp.focusflowbepresent.com"),
  title: {
    default: "FocusFlow - Web App",
    template: "%s | FocusFlow",
  },
  description: "Sign in to your FocusFlow account to access your focus sessions, tasks, and progress.",
  robots: {
    index: false, // Don't index the web app
    follow: false,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" data-theme="dark" suppressHydrationWarning>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
        <meta name="theme-color" content="#0A0A0B" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        {/* Prevent flash of unstyled content - set theme before React hydrates */}
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                const theme = localStorage.getItem('theme') || 'dark';
                document.documentElement.setAttribute('data-theme', theme);
                const metaThemeColor = document.querySelector('meta[name="theme-color"]');
                if (metaThemeColor) {
                  metaThemeColor.setAttribute('content', theme === 'dark' ? '#0A0A0B' : '#F5F0E8');
                }
              })();
            `,
          }}
        />
      </head>
      <body
        className={`${sora.variable} ${inter.variable} antialiased min-h-screen flex flex-col bg-[var(--background)]`}
      >
        <AuthProvider>
          {children}
        </AuthProvider>
      </body>
    </html>
  );
}
