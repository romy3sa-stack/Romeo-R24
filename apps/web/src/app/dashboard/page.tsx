import { Logo } from '@/components/logo';
import { createClient } from '@/lib/supabase/server';
import Link from 'next/link';
import { redirect } from 'next/navigation';

export default async function DashboardPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login');
  }

  const { data: profile } = await supabase
    .from('users')
    .select('full_name, role')
    .eq('id', user.id)
    .single();

  return (
    <div className="min-h-full bg-[#F5F7FA]">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
          <Logo variant="compact" href="/" />
          <form action="/auth/signout" method="post">
            <button
              type="submit"
              className="text-sm font-medium text-slate-600 hover:text-slate-900"
            >
              Sign out
            </button>
          </form>
        </div>
      </header>

      <main className="mx-auto max-w-5xl px-4 py-10">
        <h1 className="text-2xl font-semibold text-slate-900">
          Hello{profile?.full_name ? `, ${profile.full_name}` : ''}
        </h1>
        <p className="mt-1 text-slate-500">{user.email}</p>
        {profile?.role && (
          <p className="mt-1 text-sm text-slate-400 capitalize">
            Role: {profile.role.replace(/_/g, ' ')}
          </p>
        )}

        <div className="mt-10 grid gap-4 sm:grid-cols-3">
          <DashboardCard
            title="Receipts"
            description="Scan, upload, and manage your receipt wallet."
            href="#"
            badge="Flutter app"
          />
          <DashboardCard
            title="Insights"
            description="Spending trends, categories, and alerts."
            href="#"
            badge="Flutter app"
          />
          <DashboardCard
            title="Account"
            description="Security, notifications, and subscription settings."
            href="#"
            badge="Flutter app"
          />
        </div>

        <p className="mt-8 text-sm text-slate-500">
          Full features are available in the Flutter consumer app. This Next.js
          portal provides SSR-authenticated access and will host additional web
          features.
        </p>
      </main>
    </div>
  );
}

function DashboardCard({
  title,
  description,
  href,
  badge,
}: {
  title: string;
  description: string;
  href: string;
  badge?: string;
}) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5">
      {badge && (
        <span className="mb-2 inline-block rounded-full bg-[#00B4D8]/10 px-2 py-0.5 text-xs font-medium text-[#001A4D]">
          {badge}
        </span>
      )}
      <h2 className="font-semibold text-slate-900">{title}</h2>
      <p className="mt-1 text-sm text-slate-500">{description}</p>
      <Link
        href={href}
        className="mt-4 inline-block text-sm font-medium text-[#00B4D8] hover:underline"
      >
        Open →
      </Link>
    </div>
  );
}
