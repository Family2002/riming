import { Suspense } from "react";

import { LoginForm } from "@/components/auth/LoginForm";

export default function LoginPage() {
  return (
    <main className="mx-auto flex min-h-full max-w-md flex-1 flex-col justify-center px-6 py-16">
      <div className="login-settle">
        <p className="brand-mark text-4xl text-[var(--ink)] sm:text-5xl">日铭</p>
        <p className="mt-3 text-[var(--muted)] leading-relaxed">
          网页分析与导出。使用与手机端相同的邮箱和密码。
        </p>
        <div className="panel mt-8">
          <Suspense
            fallback={<p className="text-sm text-[var(--muted)]">加载中…</p>}
          >
            <LoginForm />
          </Suspense>
        </div>
      </div>
    </main>
  );
}
