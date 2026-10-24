import Link from "next/link";
import { connection } from "next/server";
import { notFound } from "next/navigation";
import { Suspense } from "react";

import { DayHourStrip } from "@/components/charts/DayHourStrip";
import { DayTimeline } from "@/components/charts/DayTimeline";
import { HorizontalBars } from "@/components/charts/HorizontalBars";
import { AnalyticsNote } from "@/components/ui/AnalyticsNote";
import { Card } from "@/components/ui/Card";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { KpiStrip } from "@/components/ui/KpiStrip";
import { PageLoading } from "@/components/ui/PageLoading";
import { fetchActivities } from "@/lib/activities";
import {
  filterByLocalDate,
  topByTitle,
  totalDuration,
} from "@/lib/analytics/aggregate";
import {
  addDays,
  formatDateZh,
  formatDuration,
  parseLocalDateKey,
  toLocalDateKey,
} from "@/lib/analytics/format";

type Params = Promise<{ date: string }>;

export default function DayPage({ params }: { params: Params }) {
  return (
    <Suspense fallback={<PageLoading />}>
      <DayContent params={params} />
    </Suspense>
  );
}

async function DayContent({ params }: { params: Params }) {
  await connection();
  const { date } = await params;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    notFound();
  }
  const day = parseLocalDateKey(date);
  if (Number.isNaN(day.getTime()) || toLocalDateKey(day) !== date) {
    notFound();
  }

  const nextDay = addDays(day, 1);
  const result = await fetchActivities({
    fromIso: day.toISOString(),
    toIso: nextDay.toISOString(),
  });

  if (!result.ok) {
    return <ErrorState message={result.error} />;
  }

  const dayItems = filterByLocalDate(result.items, day);
  const tops = topByTitle(dayItems, 12);
  const total = totalDuration(dayItems);
  const hasOngoing = dayItems.some((a) => a.ongoing);
  const distinctTitles = new Set(dayItems.map((i) => i.title)).size;
  const longest = dayItems.reduce(
    (max, a) => (a.durationSec > max ? a.durationSec : max),
    0,
  );

  const prev = toLocalDateKey(addDays(day, -1));
  const next = toLocalDateKey(addDays(day, 1));
  const todayKey = toLocalDateKey(new Date());

  return (
    <div className="space-y-7">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-sm text-[var(--muted)]">
            <Link
              href="/app"
              className="underline-offset-4 hover:text-[var(--lacquer)] hover:underline"
            >
              总览
            </Link>
            <span className="mx-2 text-[var(--border)]">/</span>
            当日
          </p>
          <h1 className="mt-1.5 brand-mark text-3xl text-[var(--ink)]">
            {formatDateZh(day)}
          </h1>
          <div className="mt-2">
            <AnalyticsNote />
          </div>
        </div>
        <div className="flex gap-2 text-sm">
          <Link href={`/app/day/${prev}`} className="btn-secondary py-1.5 text-sm">
            前一天
          </Link>
          {date < todayKey ? (
            <Link href={`/app/day/${next}`} className="btn-secondary py-1.5 text-sm">
              后一天
            </Link>
          ) : null}
        </div>
      </div>

      {dayItems.length === 0 ? (
        <EmptyState
          title="这一天没有记录"
          description="换一天看看，或在手机端记一笔后再同步。"
        />
      ) : (
        <>
          <KpiStrip
            items={[
              {
                label: "合计时长",
                value: formatDuration(total),
                hint: hasOngoing ? "含进行中" : undefined,
              },
              {
                label: "记录段数",
                value: `${dayItems.length}`,
              },
              {
                label: "事项种类",
                value: `${distinctTitles}`,
              },
              {
                label: "最长一段",
                value: longest > 0 ? formatDuration(longest) : "—",
              },
            ]}
          />

          <Card title="24 小时占用">
            <p className="mb-3 text-sm text-[var(--muted)]">
              上：各小时占用密度 · 下：事项泳道时间线
            </p>
            <DayHourStrip items={dayItems} dateKey={date} />
          </Card>

          <div className="grid gap-6 lg:grid-cols-2">
            <Card title="事项时长">
              <HorizontalBars
                items={tops}
                height={Math.max(220, tops.length * 36 + 40)}
              />
            </Card>
            <Card title="分段明细">
              <DayTimeline items={dayItems} dateKey={date} listOnly />
            </Card>
          </div>
        </>
      )}
    </div>
  );
}
