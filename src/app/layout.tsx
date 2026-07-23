import type { Metadata } from "next";
import { Barlow_Condensed, IBM_Plex_Mono, IBM_Plex_Sans } from "next/font/google";
import Script from "next/script";

import { ThemeProvider } from "@/components/ui/ThemeProvider";
import { THEME_BOOTSTRAP_SCRIPT } from "@/lib/ui/theme";

import "./globals.css";

const display = Barlow_Condensed({
  variable: "--font-display",
  weight: ["500", "600", "700"],
  subsets: ["latin"],
});

const body = IBM_Plex_Sans({
  variable: "--font-body",
  weight: ["400", "500", "600"],
  subsets: ["latin"],
});

const mono = IBM_Plex_Mono({
  variable: "--font-mono",
  weight: ["400", "500"],
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Destiny 2 Build Creator",
  description:
    "Local-first Destiny 2 build generator on the final 9.7.0 sandbox: local LLM research, real manifest validation, DIM exports.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
return (
<html
      lang="en"
      className={`${display.variable} ${body.variable} ${mono.variable} h-full antialiased`}
      data-theme="dark"
      data-theme-pref="system"
      suppressHydrationWarning
    >
      <body className="h-full overflow-hidden flex flex-col">
        <Script
          id="theme-bootstrap"
          strategy="beforeInteractive"
          dangerouslySetInnerHTML={{ __html: THEME_BOOTSTRAP_SCRIPT }}
        />
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
