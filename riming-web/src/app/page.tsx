import Link from "next/link";

export default function HomePage() {
  // Auth redirect for signed-in users is handled in proxy (session.ts).
  return (
    <main className="mx-auto flex min-h-full max-w-lg flex-1 flex-col justify-center px-6 py-16">
      <div className="login-settle">
        <p className="brand-mark text-5xl text-[var(--ink)] sm:text-6xl">日铭</p>
        <p className="mt-4 max-w-sm text-[1.05rem] leading-relaxed text-[var(--muted)]">
          手机负责记录；网页查看热力图、区间统计并导出 CSV。
        </p>
        <Link href="/login" className="btn-primary mt-8 w-fit">
          登录
        </Link>
      </div>
    </main>
  );
}
