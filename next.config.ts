import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Desktop packaging (Electron sidecar) and self-host deploys use the
  // standalone server bundle — see docs/packaging-desktop.md.
  output: "standalone",
  serverExternalPackages: ["better-sqlite3"],
  allowedDevOrigins: ["127.0.0.1"],
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "www.bungie.net",
        pathname: "/common/destiny2_content/**",
      },
    ],
  },
};

export default nextConfig;
