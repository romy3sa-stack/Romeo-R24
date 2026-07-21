import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  // Monorepo: trace dependencies from repo root when deployed via Vercel
  outputFileTracingRoot: path.join(__dirname, "../.."),
};

export default nextConfig;
