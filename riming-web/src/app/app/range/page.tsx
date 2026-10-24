import { connection } from "next/server";
import { Suspense } from "react";

import { RangeExplorer } from "@/components/range/RangeExplorer";
import { AnalyticsNote } from "@/components/ui/AnalyticsNote";
import { ErrorState } from "@/components/ui/ErrorState";
import { PageLoading } from "@/components/ui/PageLoading";
import { fetchActivities } from "@/lib/activities";
import {
  addDays,
  startOfLocalMonth,
  toLocalDateKey,
} from "@/lib/analytics/format";

export default function RangePage() {
  return (
    <Suspense fallback={<PageLoading />}>
      <RangeContent />
    </Suspense>
  );
}

async function RangeContent() {
  await connection();
  const now = new Date();
  const initialTo = toLocalDateKey(now);
  const initialFrom = toLocalDateKey(startOfLocalMonth(now));

  const fetchFrom = addDays(now, -370);
  const result = await fetchActivities({
    fromIso: fetchFrom.toISOString(),
    toIso: addDays(now, 1).toISOString(),
  });

  if (!result.ok) {
    return <ErrorState message={result.error} />;
  }

  return (
    <div className="app-stack">
      <header className="app-header">
        <div>
          <h1 className="brand-mark text-[1.85rem] text-[var(--ink)] sm:text-3xl">
            区间分析
          </h1>
          <p className="app-header-meta">
            选择日期范围查看趋势、占比、Top 事项，并导出 CSV
          </p>
          <div className="mt-1">
            <AnalyticsNote />
          </div>
        </div>
      </header>
      <RangeExplorer
        activities={result.items}
        initialFrom={initialFrom}
        initialTo={initialTo}
      />
    </div>
  );
}
