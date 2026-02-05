import type { NextConfig } from "next";

const isTauri = process.env.TAURI_ENV === 'true';

const nextConfig: NextConfig = {
  // Use 'export' for Tauri (static files), 'standalone' for Railway (Docker)
  output: isTauri ? 'export' : 'standalone',

  // Required for static export
  images: isTauri ? { unoptimized: true } : undefined,

  // Ensure trailing slashes for static export compatibility
  trailingSlash: isTauri ? true : false,
};

export default nextConfig;
