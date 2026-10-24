export function PageLoading({ label = "加载中…" }: { label?: string }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-12">
      <span
        className="h-1.5 w-16 overflow-hidden rounded-full bg-[var(--border)]"
        aria-hidden
      >
        <span className="block h-full w-1/2 animate-pulse rounded-full bg-[var(--lacquer)]" />
      </span>
      <p className="text-sm text-[var(--muted)]">{label}</p>
    </div>
  );
}
