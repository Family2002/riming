import type { ReactNode } from "react";

type CardProps = {
  title?: string;
  action?: ReactNode;
  children: ReactNode;
  className?: string;
};

/** Solid readable panel for charts and dense content — not decorative glass. */
export function Card({ title, action, children, className = "" }: CardProps) {
  return (
    <section className={`panel ${className}`}>
      {(title || action) && (
        <div className="mb-2.5 flex items-center justify-between gap-3">
          {title ? (
            <h2 className="text-[0.9rem] font-semibold tracking-tight text-[var(--ink)]">
              {title}
            </h2>
          ) : (
            <span />
          )}
          {action}
        </div>
      )}
      {children}
    </section>
  );
}
