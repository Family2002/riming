import Link from "next/link";

import { formatDuration } from "@/lib/analytics/format";
import type { ActivityWithDuration, TitleTotal } from "@/lib/analytics/types";

type Props = {
  dateKey: string;
  totalSec: number;
  ongoing: boolean;
  tops: TitleTotal[];
  items: ActivityWithDuration[];
};

export function TodayGlance({
  dateKey,
  totalSec,
  ongoing,
  tops,
  items,
}: Props) {
  return (
    <div>
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <p className="text-2xl font-semibold tabular-nums tracking-tight text-[var(--ink)]">
          {formatDuration(totalSec)}
        </p>
        <div className="flex items-center gap-2 text-sm">
          {ongoing ? (
            <span className="rounded-md bg-[var(--lacquer-soft)] px-2 py-0.5 text-[var(--lacquer)]">
              进行中
            </span>
          ) : null}
          <span className="text-[var(--muted)]">{items.length} 段</span>
        </div>
      </div>

      {tops.length === 0 ? (
        <p className="mt-4 text-sm text-[var(--muted)]">
          今天还没有记录。在手机端开记后同步即可。
        </p>
      ) : (
        <ol className="mt-4 space-y-2">
          {tops.map((t, i) => (
            <li
              key={t.title}
              className="flex items-baseline justify-between gap-3 text-sm"
            >
              <span className="min-w-0 truncate text-[var(--ink)]">
                <span className="mr-2 tabular-nums text-[var(--muted)]">
                  {i + 1}.
                </span>
                {t.title}
              </span>
              <span className="shrink-0 tabular-nums text-[var(--muted)]">
                {formatDuration(t.durationSec)}
              </span>
            </li>
          ))}
        </ol>
      )}

      <Link
        href={`/app/day/${dateKey}`}
        className="mt-4 inline-block text-sm font-medium text-[var(--lacquer)] underline-offset-4 hover:underline"
      >
        查看今日明细
      </Link>
    </div>
  );
}
