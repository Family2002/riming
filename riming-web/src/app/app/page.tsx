import Link from "next/link";
import { connection } from "next/server";
import { Suspense } from "react";

import { HourHistogram } from "@/components/charts/HourHistogram";
import { HorizontalBars } from "@/components/charts/HorizontalBars";
import { MonthHeatmap } from "@/components/charts/MonthHeatmap";
import { StackedDailyBars } from "@/components/charts/StackedDailyBars";
import { AnalyticsNote } from "@/components/ui/AnalyticsNote";
import { Card } from "@/components/ui/Card";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { KpiStrip } from "@/components/ui/KpiStrip";
import { PageLoading } from "@/components/ui/PageLoading";
import { TodayGlance } from "@/components/ui/TodayGlance";
import { fetchActivities } from "@/lib/activities";
import {
  dailyTotals,
  filterByLocalDate,
  filterByLocalDateRange,
  hourHistogram,
  overviewKpis,
  stackedDailyByTitle,
  topByTitle,
  totalDuration,
} from "@/lib/analytics/aggregate";
import {
  addDays,
  endOfLocalMonth,
  formatDateRangeZh,
  formatDuration,
  startOfLocalDay,
  startOfLocalMonth,
  toLocalDateKey,
} from "@/lib/analytics/format";

type SearchParams = Promise<{ year?: string; month?: string }>;

export default function OverviewPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  return (
    <Suspense fallback={<PageLoading />}>
      <OverviewContent searchParams={searchParams} />
    </Suspense>
  );
}

async function OverviewContent({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  await connection();
  const sp = await searchParams;
  const now = new Date();
  const year = Number(sp.year) || now.getFullYear();
  const month = Number(sp.month) || now.getMonth() + 1;

  const monthStart = new Date(year, month - 1, 1);
  const monthEnd = endOfLocalMonth(monthStart);
  const weekEnd = now;
  const weekStart = addDays(startOfLocalDay(now), -6);
  const todayKey = toLocalDateKey(now);
  const todayDate = startOfLocalDay(now);

  const fetchFrom = addDays(startOfLocalMonth(monthStart), -7);
  const fetchTo = addDays(endOfLocalMonth(monthStart), 1);
  const result = await fetchActivities({
    fromIso: fetchFrom.toISOString(),
    toIso: fetchTo.toISOString(),
  });

  if (!result.ok) {
    return <ErrorState message={result.error} />;
  }

  const all = result.items;
  const monthItems = filterByLocalDateRange(all, monthStart, monthEnd);
  const weekItems = filterByLocalDateRange(all, weekStart, weekEnd);
  const todayItems = filterByLocalDate(all, todayDate);
  const monthDays = dailyTotals(monthItems, monthStart, monthEnd);
  const weekStacked = stackedDailyByTitle(weekItems, weekStart, weekEnd, 5);
  const monthTops = topByTitle(monthItems, 8);
  const todayTops = topByTitle(todayItems, 3);
  const kpis = overviewKpis(monthItems, weekItems);
  const hourBuckets = hourHistogram(monthItems, now);
  const hasMonthData = monthItems.length > 0;
  const todayOngoing = todayItems.some((a) => a.ongoing);

  const prev = new Date(year, month - 2, 1);
  const next = new Date(year, month, 1);
  const canNext =
    next.getFullYear() < now.getFullYear() ||
    (next.getFullYear() === now.getFullYear() &&
      next.getMonth() <= now.getMonth());

  return (
    <div className="app-stack">
      <div className="app-header">
        <div>
          <h1 className="brand-mark text-3xl text-[var(--ink)]">总览</h1>
          <p className="app-header-meta">
            点击热力图中的日期可查看当日明细
          </p>
          <div className="mt-2">
            <AnalyticsNote />
          </div>
        </div>
        <Link
          href="/app/range"
          className="text-sm font-medium text-[var(--lacquer)] underline-offset-4 hover:underline"
        >
          区间分析与导出
        </Link>
      </div>

      <KpiStrip
        items={[
          {
            label: "本月合计时长",
            value: formatDuration(kpis.monthTotalSec),
          },
          {
            label: "近 7 天合计",
            value: formatDuration(kpis.weekTotalSec),
          },
          {
            label: "活跃天数",
            value: `${kpis.activeDays} 天`,
            hint: `${year}年${month}月`,
          },
          {
            label: "活动种类数",
            value: `${kpis.titleCount}`,
          },
        ]}
      />

      <div className="overview-hero">
        <Card title="今日快览">
          <TodayGlance
            dateKey={todayKey}
            totalSec={totalDuration(todayItems)}
            ongoing={todayOngoing}
            tops={todayTops}
            items={todayItems}
          />
        </Card>
        <Card
          title={`${year}年${month}月`}
          action={
            <div className="flex items-center gap-2 text-sm">
              <Link
                href={`/app?year=${prev.getFullYear()}&month=${prev.getMonth() + 1}`}
                className="btn-secondary px-2.5 py-1 text-sm"
              >
                上月
              </Link>
              {canNext ? (
                <Link
                  href={`/app?year=${next.getFullYear()}&month=${next.getMonth() + 1}`}
                  className="btn-secondary px-2.5 py-1 text-sm"
                >
                  下月
                </Link>
              ) : null}
            </div>
          }
        >
          {!hasMonthData ? (
            <EmptyState
              title="本月还没有记录"
              description="在手机端开始记事后，同步账号即可在此看到热力图。"
            />
          ) : (
            <MonthHeatmap year={year} month={month} days={monthDays} />
          )}
        </Card>
      </div>

      <div className="chart-grid">
        <Card title="近 7 天（按事项堆叠）">
          {weekItems.length === 0 ? (
            <EmptyState
              title="近 7 天暂无数据"
              description="有记录后会显示按事项堆叠的每日时长。"
            />
          ) : (
            <>
              <p className="mb-3 text-sm text-[var(--muted)]">
                {formatDateRangeZh(weekStart, weekEnd)} · Top 5 + 其他
              </p>
              <StackedDailyBars data={weekStacked} height={300} />
            </>
          )}
        </Card>
        <Card title="本月 Top 事项">
          {monthTops.length === 0 ? (
            <EmptyState title="暂无事项排行" />
          ) : (
            <HorizontalBars
              items={monthTops}
              height={Math.max(260, monthTops.length * 40 + 40)}
            />
          )}
        </Card>
      </div>

      <Card title="时段分布（本月）">
        {!hasMonthData ? (
          <EmptyState
            title="暂无时段分布"
            description="本月有记录后，可看出一天中哪些小时更常记事。"
          />
        ) : (
          <>
            <p className="mb-3 text-sm text-[var(--muted)]">
              按墙钟小时累计占用时长（进行中计到当前）
            </p>
            <HourHistogram buckets={hourBuckets} height={280} />
          </>
        )}
      </Card>
    </div>
  );
}
