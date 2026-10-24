"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { FormEvent, useState } from "react";

import { friendlyAuthError } from "@/lib/auth/messages";
import { createClient } from "@/lib/supabase/client";

type Mode = "login" | "register";

export function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const next = searchParams.get("next") || "/app";

  const [mode, setMode] = useState<Mode>("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  function switchMode(nextMode: Mode) {
    setMode(nextMode);
    setError(null);
    setInfo(null);
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setInfo(null);
    setLoading(true);
    try {
      const supabase = createClient();
      const trimmed = email.trim();

      if (mode === "register") {
        const { data, error: signError } = await supabase.auth.signUp({
          email: trimmed,
          password,
        });
        if (signError) {
          setError(friendlyAuthError(signError.message, signError.code));
          return;
        }
        const identities = data.user?.identities;
        if (data.user && identities && identities.length === 0) {
          setError("该邮箱已注册，请直接登录");
          return;
        }
        if (data.session) {
          router.push(next.startsWith("/") ? next : "/app");
          router.refresh();
          return;
        }
        setInfo(
          "注册成功。请到邮箱查收确认邮件，点击链接完成验证后再登录。",
        );
        setMode("login");
        return;
      }

      const { error: signError } = await supabase.auth.signInWithPassword({
        email: trimmed,
        password,
      });
      if (signError) {
        setError(friendlyAuthError(signError.message, signError.code));
        return;
      }
      router.push(next.startsWith("/") ? next : "/app");
      router.refresh();
    } catch {
      setError(mode === "register" ? "注册失败，请稍后重试" : "登录失败，请稍后重试");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <div>
        <label
          htmlFor="email"
          className="mb-1.5 block text-sm font-medium text-[var(--ink)]"
        >
          邮箱
        </label>
        <input
          id="email"
          type="email"
          autoComplete="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="input-field"
          placeholder="与手机端相同的账号"
        />
      </div>
      <div>
        <label
          htmlFor="password"
          className="mb-1.5 block text-sm font-medium text-[var(--ink)]"
        >
          密码
        </label>
        <input
          id="password"
          type="password"
          autoComplete={
            mode === "register" ? "new-password" : "current-password"
          }
          required
          minLength={6}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="input-field"
          placeholder="至少 6 位"
        />
      </div>
      {error ? (
        <p
          className="rounded-lg bg-[var(--danger-soft)] px-3 py-2 text-sm text-[var(--danger)]"
          role="alert"
        >
          {error}
        </p>
      ) : null}
      {info ? (
        <p
          className="rounded-lg bg-[var(--lacquer-soft)] px-3 py-2 text-sm text-[var(--lacquer)]"
          role="status"
        >
          {info}
        </p>
      ) : null}
      <button type="submit" disabled={loading} className="btn-primary w-full">
        {loading
          ? mode === "register"
            ? "注册中…"
            : "登录中…"
          : mode === "register"
            ? "注册"
            : "登录"}
      </button>
      <p className="text-center text-sm text-[var(--muted)]">
        {mode === "login" ? (
          <>
            还没有账号？{" "}
            <button
              type="button"
              className="font-medium text-[var(--lacquer)] hover:underline"
              onClick={() => switchMode("register")}
            >
              注册
            </button>
          </>
        ) : (
          <>
            已有账号？{" "}
            <button
              type="button"
              className="font-medium text-[var(--lacquer)] hover:underline"
              onClick={() => switchMode("login")}
            >
              登录
            </button>
          </>
        )}
      </p>
    </form>
  );
}
