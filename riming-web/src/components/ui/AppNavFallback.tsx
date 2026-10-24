/** Static shell while AppNav (pathname-aware) streams in. */
export function AppNavFallback() {
  return (
    <header className="sticky top-0 z-40 border-b border-[var(--border)] bg-[var(--chrome)] backdrop-blur-md">
      <div className="mx-auto flex h-14 max-w-6xl items-center px-6">
        <span className="brand-mark text-xl text-[var(--ink)]">日铭</span>
      </div>
    </header>
  );
}
