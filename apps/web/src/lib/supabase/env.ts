export type SupabaseConfig = {
  url: string;
  key: string;
};

/** Returns config when env vars are set; null in middleware when they are missing. */
export function tryGetSupabaseConfig(): SupabaseConfig | null {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key =
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) {
    return null;
  }
  return { url, key };
}

export function getSupabaseUrl(): string {
  const config = tryGetSupabaseConfig();
  if (!config) {
    throw new Error('Missing NEXT_PUBLIC_SUPABASE_URL');
  }
  return config.url;
}

/** Supports new publishable keys (sb_publishable_*) and legacy anon JWT keys. */
export function getSupabaseKey(): string {
  const config = tryGetSupabaseConfig();
  if (!config) {
    throw new Error(
      'Missing NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY or NEXT_PUBLIC_SUPABASE_ANON_KEY',
    );
  }
  return config.key;
}
