import type { Metadata } from "next";
import { Sora, Inter } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/contexts/AuthContext";
import { QueryProvider } from "@/components/providers/QueryProvider";

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
                // Set dark/light mode
                const darkMode = localStorage.getItem('focusflow-dark-mode') || 'dark';
                document.documentElement.setAttribute('data-theme', darkMode);
                const metaThemeColor = document.querySelector('meta[name="theme-color"]');
                if (metaThemeColor) {
                  metaThemeColor.setAttribute('content', darkMode === 'dark' ? '#0A0A0B' : '#F5F0E8');
                }
                
                // Apply color theme (only accent colors, NOT backgrounds)
                const colorTheme = localStorage.getItem('focusflow-color-theme') || 'forest';
                const themes = {
                  forest: { accentPrimary: 'rgb(140, 230, 179)', accentSecondary: 'rgb(107, 199, 158)' },
                  neon: { accentPrimary: 'rgb(64, 242, 217)', accentSecondary: 'rgb(153, 102, 255)' },
                  peach: { accentPrimary: 'rgb(255, 184, 161)', accentSecondary: 'rgb(255, 217, 179)' },
                  cyber: { accentPrimary: 'rgb(204, 153, 255)', accentSecondary: 'rgb(97, 220, 255)' },
                  ocean: { accentPrimary: 'rgb(122, 214, 255)', accentSecondary: 'rgb(59, 242, 245)' },
                  sunrise: { accentPrimary: 'rgb(255, 158, 161)', accentSecondary: 'rgb(255, 204, 140)' },
                  amber: { accentPrimary: 'rgb(255, 199, 115)', accentSecondary: 'rgb(255, 153, 102)' },
                  mint: { accentPrimary: 'rgb(153, 245, 199)', accentSecondary: 'rgb(117, 224, 235)' },
                  royal: { accentPrimary: 'rgb(166, 184, 255)', accentSecondary: 'rgb(128, 153, 255)' },
                  slate: { accentPrimary: 'rgb(191, 209, 245)', accentSecondary: 'rgb(179, 194, 230)' }
                };
                
                if (themes[colorTheme]) {
                  const colors = themes[colorTheme];
                  const root = document.documentElement;
                  // Only set accent colors, backgrounds stay from main site CSS
                  root.style.setProperty('--accent-primary', colors.accentPrimary);
                  root.style.setProperty('--accent-secondary', colors.accentSecondary);
                }
              })();
            `,
          }}
        />
      </head>
      <body
        className={`${sora.variable} ${inter.variable} antialiased min-h-screen flex flex-col bg-[var(--background)]`}
      >
        <QueryProvider>
          <AuthProvider>
            {children}
          </AuthProvider>
        </QueryProvider>
      </body>
    </html>
  );
}
