import type { Metadata } from "next";
import { Sora, Inter } from "next/font/google";
import "./globals.css";
import Header from "@/components/layout/Header";
import Footer from "@/components/layout/Footer";
import ScrollToTop from "@/components/ui/ScrollToTop";

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
  title: "Soft Computers | Premium Software for Focused Work",
  description: "We build premium software that helps people do meaningful work—calmly, consistently, and with intention. Discover FocusFlow, our flagship focus timer app.",
  keywords: ["focus timer", "productivity", "task management", "iOS app", "focus app", "pomodoro"],
  authors: [{ name: "Soft Computers" }],
  openGraph: {
    title: "Soft Computers | Premium Software for Focused Work",
    description: "We build premium software that helps people do meaningful work—calmly, consistently, and with intention.",
    type: "website",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: "Soft Computers | Premium Software for Focused Work",
    description: "We build premium software that helps people do meaningful work.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body
        className={`${sora.variable} ${inter.variable} antialiased min-h-screen flex flex-col`}
      >
        <Header />
        <main className="flex-1">{children}</main>
        <Footer />
        <ScrollToTop />
      </body>
    </html>
  );
}
