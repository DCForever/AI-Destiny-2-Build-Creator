import { Suspense } from "react";

import { BungieAuthControl } from "@/components/BungieAuthControl";

const NAV_LINKS = [
  { href: "/loadouts", label: "In-Game Loadouts", key: "loadouts" as const },
  { href: "/build", label: "Build", key: "build" as const },
  { href: "/synergy", label: "Synergy", key: "synergy" as const },
  { href: "/sets", label: "Sets", key: "sets" as const },
  { href: "/catalog", label: "Catalog", key: "catalog" as const },
  { href: "/settings", label: "Settings", key: "settings" as const },
];

export type AppShellActive = (typeof NAV_LINKS)[number]["key"];

interface AppShellProps {
  active: AppShellActive;
  children: React.ReactNode;
}

export function AppShell({ active, children }: AppShellProps) {
  return (
    <div className="flex flex-col min-h-screen">
      <header className="border-b border-line bg-surface sticky top-0 z-10">
        <div className="max-w-[1600px] mx-auto px-6 h-14 flex items-center justify-between">
          <span className="font-display text-sm tracking-[0.18em] uppercase text-accent select-none">
            DESTINY 2 // BUILD CREATOR
          </span>
          <div className="flex items-center gap-6">
            <nav className="flex items-center gap-6" aria-label="Main navigation">
              {NAV_LINKS.map(({ href, label, key }) => (
                <a
                  key={href}
                  href={href}
                  className={`text-[11px] tracking-widest uppercase transition-colors ${
                    active === key
                      ? "text-accent"
                      : "text-muted hover:text-foreground"
                  }`}
                >
                  {label}
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
