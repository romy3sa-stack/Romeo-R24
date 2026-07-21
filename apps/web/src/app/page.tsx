import { createClient } from '@/lib/supabase/server';
import Link from 'next/link';

export default async function HomePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return (
    <div className="flex min-h-full flex-col bg-[#001A4D] text-white">
      <header className="mx-auto flex w-full max-w-6xl items-center justify-between px-6 py-6">
        <span className="text-xl font-bold">Receipt24</span>
        <nav className="flex items-center gap-4">
          {user ? (
            <Link
              href="/dashboard"
              className="rounded-lg bg-[#00B4D8] px-4 py-2 text-sm font-medium text-[#001A4D] hover:bg-[#33c5e0]"
            >
              Dashboard
            </Link>
          ) : (
            <Link
              href="/login"
              className="rounded-lg border border-white/30 px-4 py-2 text-sm font-medium hover:bg-white/10"
            >
              Sign in
            </Link>
          )}
        </nav>
      </header>

      <main className="mx-auto flex flex-1 w-full max-w-6xl flex-col items-start justify-center px-6 py-20">
        <p className="text-sm font-medium uppercase tracking-widest text-[#00B4D8]">
          Digital receipt management
        </p>
        <h1 className="mt-4 max-w-2xl text-5xl font-bold leading-tight">
          Every Receipt. One Place.
        </h1>
        <p className="mt-6 max-w-xl text-lg text-white/80">
          Scan, upload, organise, and analyse receipts. Track warranties,
          manage expenses, and share with your accountant — all in one secure
          platform.
        </p>
        <div className="mt-10 flex flex-wrap gap-4">
          <Link
            href={user ? '/dashboard' : '/login'}
            className="rounded-lg bg-[#00B4D8] px-6 py-3 font-medium text-[#001A4D] hover:bg-[#33c5e0]"
          >
            {user ? 'Go to dashboard' : 'Get started'}
          </Link>
          <a
            href="https://github.com/romy3sa-stack/Romeo-R24"
            className="rounded-lg border border-white/30 px-6 py-3 font-medium hover:bg-white/10"
            target="_blank"
            rel="noopener noreferrer"
          >
            View on GitHub
          </a>
        </div>
      </main>

      <footer className="mx-auto w-full max-w-6xl px-6 py-8 text-sm text-white/50">
        © {new Date().getFullYear()} Receipt24. Proprietary — All rights reserved.
      </footer>
    </div>
  );
}
