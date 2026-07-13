import { Suspense } from "react";

import { BungieAuthControl } from "@/components/BungieAuthControl";

const NAV_LINKS = [
  { href: "/loadouts", label: "In-Game Loadouts", short: "Loadouts", key: "loadouts" as const },
  { href: "/build", label: "Build", short: "Build", key: "build" as const },
  { href: "/synergy", label: "Synergy", short: "Synergy", key: "synergy" as const },
  { href: "/sets", label: "Sets", short: "Sets", key: "sets" as const },
  { href: "/catalog", label: "Catalog", short: "Catalog", key: "catalog" as const },
  { href: "/settings", label: "Settings", short: "Settings", key: "settings" as const },
];

export type AppShellActive = (typeof NAV_LINKS)[number]["key"];

interface AppShellProps {
  active: AppShellActive;
  children: React.ReactNode;
}

export function AppShell({ active, children }: AppShellProps) {
  return (
    <div className="flex flex-col min-h-screen">
      <header className="border-b border-line bg-surface/95 backdrop-blur-sm sticky top-0 z-20">
        <div className="max-w-[1600px] mx-auto px-3 sm:px-6 h-12 sm:h-14 flex items-center justify-between gap-3">
          <span className="font-display text-[10px] sm:text-sm tracking-[0.14em] sm:tracking-[0.18em] uppercase text-accent select-none shrink-0">
            <span className="hidden sm:inline">DESTINY 2 // BUILD CREATOR</span>
            <span className="sm:hidden">D2 // BC</span>
          </span>
          <div className="flex items-center gap-2 sm:gap-6 min-w-0">
            <nav
              className="flex items-center gap-1 sm:gap-4 overflow-x-auto max-w-[min(100vw-8rem,42rem)] scrollbar-none"
              aria-label="Main navigation"
            >
              {NAV_LINKS.map(({ href, label, short, key }) => (
                <a
                  key={href}
                  href={href}
                  className={`shrink-0 text-[9px] sm:text-[11px] tracking-widest uppercase px-1.5 sm:px-0 py-1 transition-colors border-b-2 ${
                    active === key
                      ? "text-accent border-accent"
                      : "text-muted border-transparent hover:text-foreground"
                  }`}
                >
                  <span className="sm:hidden">{short}</span>
                  <span className="hidden sm:inline">{label}</span>
                </a>
              ))}
            </nav>
            <Suspense fallback={null}>
              <BungieAuthControl compact />
            </Suspense>
          </div>
        </div>
      </header>
      {children}
    </div>
  );
}
