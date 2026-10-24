"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

import { createClient } from "@/lib/supabase/client";

const links = [
  { href: "/app", label: "总览", exact: true },
  { href: "/app/range", label: "区间", exact: false },
];

export function AppNav({ email }: { email?: string | null }) {
  const pathname = usePathname();
  const router = useRouter();

  async function signOut() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  }

  return (
    <header className="sticky top-0 z-40 border-b border-[var(--border)] bg-[var(--chrome)] backdrop-blur-md">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between gap-6 px-6">
        <div className="flex items-center gap-7">
          <Link href="/app" className="brand-mark text-xl text-[var(--ink)]">
            日铭
          </Link>
          <nav className="flex items-center gap-0.5">
            {links.map((link) => {
              const active = link.exact
                ? pathname === link.href
                : pathname.startsWith(link.href);
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`nav-link rounded-md px-3 py-1.5 text-sm transition ${
                    active
                      ? "bg-[var(--lacquer-soft)] font-medium text-[var(--lacquer)]"
                      : "text-[var(--muted)] hover:bg-[var(--card)] hover:text-[var(--ink)]"
                  }`}
                >
                  {link.label}
                </Link>
              );
            })}
          </nav>
        </div>
        <div className="flex items-center gap-3 text-sm text-[var(--muted)]">
          {email ? (
            <span className="hidden max-w-[14rem] truncate sm:inline">
              {email}
            </span>
          ) : null}
          <button type="button" onClick={signOut} className="btn-secondary py-1.5 text-sm">
            退出
          </button>
        </div>
      </div>
    </header>
  );
}
