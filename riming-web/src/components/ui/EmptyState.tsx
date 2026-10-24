type EmptyStateProps = {
  title: string;
  description?: string;
};

/** Quiet empty copy — works inside panels without a second “card”. */
export function EmptyState({ title, description }: EmptyStateProps) {
  return (
    <div className="px-2 py-6 text-center">
      <p className="text-[0.95rem] font-medium text-[var(--ink)]">{title}</p>
      {description ? (
        <p className="mx-auto mt-1.5 max-w-sm text-sm leading-relaxed text-[var(--muted)]">
          {description}
        </p>
      ) : null}
    </div>
  );
}
