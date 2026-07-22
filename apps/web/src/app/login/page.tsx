import { LoginForm } from '@/components/login-form';
import { Logo } from '@/components/logo';
import { Suspense } from 'react';

export default function LoginPage() {
  return (
    <div className="flex min-h-full flex-1 flex-col items-center justify-center bg-[#F5F7FA] px-4 py-16">
      <div className="w-full max-w-md rounded-2xl bg-white p-8 shadow-sm">
        <div className="flex justify-center">
          <Logo variant="full" href="/" />
        </div>
        <h1 className="mt-8 text-xl font-semibold text-slate-900">Sign in</h1>
        <p className="mt-1 mb-6 text-sm text-slate-500">
          Use your Receipt24 account credentials.
        </p>
        <Suspense fallback={<div className="h-40 animate-pulse rounded-lg bg-slate-100" />}>
          <LoginForm />
        </Suspense>
      </div>
    </div>
  );
}
