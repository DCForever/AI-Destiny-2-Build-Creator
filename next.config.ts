import type { NextConfig } from "next";

const nextConfig: NextConfig = {
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
