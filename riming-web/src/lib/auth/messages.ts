/** Map Supabase Auth errors to Chinese UI copy (aligned with Flutter). */
export function friendlyAuthError(message: string, code?: string): string {
  const lower = message.toLowerCase();
  const c = (code ?? "").toLowerCase();

  if (
    c === "email_not_confirmed" ||
    lower.includes("email not confirmed")
  ) {
    return "请先到邮箱确认账号";
  }
  if (
    c === "invalid_credentials" ||
    lower.includes("invalid login") ||
    lower.includes("invalid credentials")
  ) {
    return "邮箱或密码不正确";
  }
  if (
    c === "user_already_exists" ||
    lower.includes("user already registered") ||
    lower.includes("already been registered") ||
    lower.includes("already registered")
  ) {
    return "该邮箱已注册，请直接登录";
  }
  if (lower.includes("password") && lower.includes("at least")) {
    return "密码至少需要 6 位";
  }
  if (lower.includes("rate limit") || lower.includes("too many")) {
    return "尝试过于频繁，请稍后再试";
  }
  return message;
}
