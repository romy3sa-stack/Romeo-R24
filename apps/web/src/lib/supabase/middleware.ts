import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

import { tryGetSupabaseConfig } from './env';

function redirectToLogin(request: NextRequest) {
  const url = request.nextUrl.clone();
  url.pathname = '/login';
  url.searchParams.set('redirect', request.nextUrl.pathname);
  return NextResponse.redirect(url);
}

export async function updateSession(request: NextRequest) {
  const config = tryGetSupabaseConfig();
  if (!config) {
    // Missing env vars on Vercel — avoid crashing middleware (500).
    if (request.nextUrl.pathname.startsWith('/dashboard')) {
      return redirectToLogin(request);
    }
    return NextResponse.next({ request });
  }

  try {
    let supabaseResponse = NextResponse.next({ request });

    const supabase = createServerClient(config.url, config.key, {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options),
          );
        },
      },
    });

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user && request.nextUrl.pathname.startsWith('/dashboard')) {
      return redirectToLogin(request);
    }

    if (user && request.nextUrl.pathname === '/login') {
      const url = request.nextUrl.clone();
      url.pathname = '/dashboard';
      url.searchParams.delete('redirect');
      return NextResponse.redirect(url);
    }

    return supabaseResponse;
  } catch {
    // Supabase unreachable or misconfigured — serve public pages, protect dashboard.
    if (request.nextUrl.pathname.startsWith('/dashboard')) {
      return redirectToLogin(request);
    }
    return NextResponse.next({ request });
  }
}
