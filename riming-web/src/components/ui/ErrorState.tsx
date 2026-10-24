type ErrorStateProps = {
  title?: string;
  message: string;
};

export function ErrorState({
  title = "加载失败",
  message,
}: ErrorStateProps) {
  return (
    <div
      className="rounded-xl border border-[var(--danger)]/25 bg-[var(--danger-soft)] px-5 py-6"
      role="alert"
    >
      <p className="font-medium text-[var(--danger)]">{title}</p>
      <p className="mt-2 text-sm leading-relaxed text-[var(--danger)]/90">
        {message}
      </p>
      <p className="mt-3 text-sm text-[var(--muted)]">
        请刷新页面重试。若持续失败，检查网络或稍后再试。
      </p>
    </div>
  );
}
