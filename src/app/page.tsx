import { GeneratorPage } from "@/components/GeneratorPage";

const NAV_LINKS = [
  { href: "/", label: "Generator", active: true },
  { href: "/analyze", label: "Analyzer", active: false },
  { href: "/settings", label: "Settings", active: false },
] as const;

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen">
      <header className="border-b border-line bg-surface sticky top-0 z-10">
        <div className="max-w-[1600px] mx-auto px-6 h-14 flex items-center justify-between">
          <span className="font-display text-sm tracking-[0.18em] uppercase text-accent select-none">
            DESTINY 2 // BUILD CREATOR
          </span>
          <nav className="flex items-center gap-6" aria-label="Main navigation">
            {NAV_LINKS.map(({ href, label, active }) => (
              <a
                key={href}
                href={href}
                className={`text-[11px] tracking-widest uppercase transition-colors ${
                  active
                    ? "text-accent"
                    : "text-muted hover:text-foreground"
                }`}
              >
                {label}
              </a>
            ))}
          </nav>
        </div>
      </header>
      <GeneratorPage />
    </div>
  );
}
