import { Logo } from '@/components/logo';
import { createClient } from '@/lib/supabase/server';
import Link from 'next/link';
import { redirect } from 'next/navigation';

type UserRole =
  | 'consumer'
  | 'accountant'
  | 'accounting_firm_manager'
  | 'super_administrator'
  | 'support_administrator';

const ROLE_LABELS: Record<UserRole, string> = {
  consumer: 'Consumer',
  accountant: 'Accountant',
  accounting_firm_manager: 'Firm Manager',
  super_administrator: 'Super Admin',
  support_administrator: 'Support Admin',
};

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
    .select('full_name, role, account_status')
    .eq('id', user.id)
    .single();

  const role = (profile?.role ?? 'consumer') as UserRole;
  const cards = getCardsForRole(role);

  const [{ count: receiptCount }, { count: notificationCount }] = await Promise.all([
    supabase
      .from('receipts')
      .select('*', { count: 'exact', head: true })
      .eq('consumer_user_id', user.id),
    supabase
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.id)
      .eq('read_status', false),
  ]);

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
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">
              Hello{profile?.full_name ? `, ${profile.full_name}` : ''}
            </h1>
            <p className="mt-1 text-slate-500">{user.email}</p>
            <p className="mt-1 text-sm text-slate-400">
              {ROLE_LABELS[role] ?? role} · {profile?.account_status ?? 'active'}
            </p>
          </div>
          <StatusBadge label="Production" status="live" />
        </div>

        {(role === 'consumer' || role === 'accountant') && (
          <div className="mt-6 flex flex-wrap gap-3">
            {role === 'consumer' && (
              <>
                <StatPill label="Receipts" value={receiptCount ?? 0} />
                <StatPill label="Unread alerts" value={notificationCount ?? 0} />
              </>
            )}
            <StatPill label="Backend" value="Connected" />
          </div>
        )}

        <div className="mt-10 grid gap-4 sm:grid-cols-3">
          {cards.map((card) => (
            <DashboardCard key={card.title} {...card} />
          ))}
        </div>

        <section className="mt-10 rounded-xl border border-slate-200 bg-white p-5">
          <h2 className="font-semibold text-slate-900">System status</h2>
          <ul className="mt-3 space-y-2 text-sm text-slate-600">
            <li>✓ Supabase auth &amp; database — live</li>
            <li>✓ Edge functions (7) — deployed</li>
            <li>✓ Web portal — https://romeo-r24.vercel.app</li>
            <li>○ Custom domain app.receipt24.com — pending DNS</li>
            <li>○ Flutter apps — build with <code className="rounded bg-slate-100 px-1">scripts/build-web.sh</code></li>
          </ul>
        </section>
      </main>
    </div>
  );
}

function getCardsForRole(role: UserRole) {
  switch (role) {
    case 'super_administrator':
      return [
        {
          title: 'User management',
          description: 'Review users, roles, and account status.',
          href: '#',
          badge: 'Admin app',
        },
        {
          title: 'Accountant verification',
          description: 'Approve or reject accountant registrations.',
          href: '#',
          badge: 'Admin app',
        },
        {
          title: 'Audit logs',
          description: 'Review platform security and activity logs.',
          href: '#',
          badge: 'Admin app',
        },
      ];
    case 'support_administrator':
      return [
        {
          title: 'Support tickets',
          description: 'Manage customer support requests.',
          href: '#',
          badge: 'Admin app',
        },
        {
          title: 'Users',
          description: 'Look up user accounts and status.',
          href: '#',
          badge: 'Admin app',
        },
        {
          title: 'Notifications',
          description: 'Send system announcements.',
          href: '#',
          badge: 'Admin app',
        },
      ];
    case 'accountant':
    case 'accounting_firm_manager':
      return [
        {
          title: 'Clients',
          description: 'View linked consumer accounts and access requests.',
          href: '#',
          badge: 'Accountant app',
        },
        {
          title: 'Receipts',
          description: 'Review client receipts and classifications.',
          href: '#',
          badge: 'Accountant app',
        },
        {
          title: 'Subscriptions',
          description: 'Manage your accountant portal plan.',
          href: '#',
          badge: 'Accountant app',
        },
      ];
    default:
      return [
        {
          title: 'Receipts',
          description: 'Scan, upload, and manage your receipt wallet.',
          href: '#',
          badge: 'Consumer app',
        },
        {
          title: 'Insights',
          description: 'Spending trends, categories, and alerts.',
          href: '#',
          badge: 'Consumer app',
        },
        {
          title: 'Account',
          description: 'Security, notifications, and subscription settings.',
          href: '#',
          badge: 'Consumer app',
        },
      ];
  }
}

function StatPill({ label, value }: { label: string; value: string | number }) {
  return (
    <span className="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-3 py-1.5 text-sm">
      <span className="text-slate-500">{label}</span>
      <span className="font-semibold text-[#001A4D]">{value}</span>
    </span>
  );
}

function StatusBadge({ label, status }: { label: string; status: 'live' | 'pending' }) {
  return (
    <span
      className={`inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-medium ${
        status === 'live'
          ? 'bg-green-50 text-green-700'
          : 'bg-amber-50 text-amber-700'
      }`}
    >
      <span
        className={`h-2 w-2 rounded-full ${
          status === 'live' ? 'bg-green-500' : 'bg-amber-500'
        }`}
      />
      {label}
    </span>
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
        <span className="mb-2 inline-block rounded-full bg-[#4CAF50]/10 px-2 py-0.5 text-xs font-medium text-[#001A4D]">
          {badge}
        </span>
      )}
      <h2 className="font-semibold text-slate-900">{title}</h2>
      <p className="mt-1 text-sm text-slate-500">{description}</p>
      <Link
        href={href}
        className="mt-4 inline-block text-sm font-medium text-[#4CAF50] hover:underline"
      >
        Open →
      </Link>
    </div>
  );
}
