"use client";

import { useMemo, useState } from "react";

import { DailyTotalsBars } from "@/components/charts/DailyTotalsBars";
import { DailyTrendLine } from "@/components/charts/DailyTrendLine";
import { HorizontalBars } from "@/components/charts/HorizontalBars";
import { ShareDonut } from "@/components/charts/ShareDonut";
import { TitleTrendLines } from "@/components/charts/TitleTrendLines";
import { Card } from "@/components/ui/Card";
import { EmptyState } from "@/components/ui/EmptyState";
import { KpiStrip } from "@/components/ui/KpiStrip";
import {
  dailyTotals,
  filterByLocalDateRange,
  titleDailyTrends,
  topByTitle,
  totalDuration,
} from "@/lib/analytics/aggregate";
import { activitiesToCsv, downloadCsv } from "@/lib/analytics/csv";
import {
  addDays,
  formatClock,
  formatDuration,
  parseLocalDateKey,
  toLocalDateKey,
} from "@/lib/analytics/format";
import type { ActivityWithDuration } from "@/lib/analytics/types";

type Props = {
  activities: ActivityWithDuration[];
  initialFrom: string;
  initialTo: string;
};

export function RangeExplorer({ activities, initialFrom, initialTo }: Props) {
  const [from, setFrom] = useState(initialFrom);
  const [to, setTo] = useState(initialTo);

  const filtered = useMemo(() => {
    const fromDate = parseLocalDateKey(from);
    const toDate = parseLocalDateKey(to);
    if (Number.isNaN(fromDate.getTime()) || Number.isNaN(toDate.getTime())) {
      return [];
    }
    const [a, b] = fromDate <= toDate ? [fromDate, toDate] : [toDate, fromDate];
    return filterByLocalDateRange(activities, a, b);
  }, [activities, from, to]);

  const rangeBounds = useMemo(() => {
    const fromDate = parseLocalDateKey(from);
    const toDate = parseLocalDateKey(to);
    if (Number.isNaN(fromDate.getTime()) || Number.isNaN(toDate.getTime())) {
      return null;
    }
    return fromDate <= toDate
      ? ([fromDate, toDate] as const)
      : ([toDate, fromDate] as const);
  }, [from, to]);

  const tops = useMemo(() => topByTitle(filtered, 15), [filtered]);
  const days = useMemo(() => {
    if (!rangeBounds) return [];
    return dailyTotals(filtered, rangeBounds[0], rangeBounds[1]);
  }, [filtered, rangeBounds]);
  const trends = useMemo(() => {
    if (!rangeBounds) return [];
    return titleDailyTrends(filtered, rangeBounds[0], rangeBounds[1], 5);
  }, [filtered, rangeBounds]);

  const total = totalDuration(filtered);
  const ongoingCount = filtered.filter((a) => a.ongoing).length;
  const activeDays = days.filter((d) => d.durationSec > 0).length;
  const distinctTitles = new Set(filtered.map((i) => i.title)).size;
  const topTitle = tops[0]?.title;
  const avgPerActiveDay =
    activeDays > 0 ? Math.round(total / activeDays) : 0;

  function exportCsv() {
    const csv = activitiesToCsv(filtered);
    downloadCsv(`riming_${from}_${to}.csv`, csv);
  }

  function setPreset(daysBack: number) {
    const end = new Date();
    const start = addDays(end, -(daysBack - 1));
    setFrom(toLocalDateKey(start));
    setTo(toLocalDateKey(end));
  }

  return (
    <div className="app-stack">
      <Card title="日期范围">
        <div className="flex flex-wrap items-end gap-3 sm:gap-4">
          <label className="text-sm">
            <span className="mb-1.5 block text-[var(--muted)]">开始</span>
            <input
              type="date"
              value={from}
              onChange={(e) => setFrom(e.target.value)}
              className="input-field w-auto"
            />
          </label>
          <label className="text-sm">
            <span className="mb-1.5 block text-[var(--muted)]">结束</span>
            <input
              type="date"
              value={to}
              onChange={(e) => setTo(e.target.value)}
              className="input-field w-auto"
            />
          </label>
          <div className="flex flex-wrap gap-2 pb-0.5">
            <PresetButton onClick={() => setPreset(7)}>近 7 天</PresetButton>
            <PresetButton onClick={() => setPreset(30)}>近 30 天</PresetButton>
            <PresetButton
              onClick={() => {
                const now = new Date();
                setFrom(
                  toLocalDateKey(
                    new Date(now.getFullYear(), now.getMonth(), 1),
                  ),
                );
                setTo(toLocalDateKey(now));
              }}
            >
              本月
            </PresetButton>
          </div>
          <button
            type="button"
            onClick={exportCsv}
            className="btn-primary sm:ml-auto"
            disabled={filtered.length === 0}
          >
            导出 CSV
          </button>
        </div>
      </Card>

      <KpiStrip
        items={[
          {
            label: "区间合计",
            value: formatDuration(total),
            hint:
              ongoingCount > 0
                ? `含 ${ongoingCount} 段进行中`
                : `${filtered.length} 段`,
          },
          {
            label: "活跃天数",
            value: `${activeDays} 天`,
            hint: `共 ${days.length} 天`,
          },
          {
            label: "事项种类",
            value: `${distinctTitles}`,
            hint: topTitle ? `最多：${topTitle}` : undefined,
          },
          {
            label: "日均（活跃日）",
            value: activeDays ? formatDuration(avgPerActiveDay) : "—",
          },
        ]}
      />

      <Card title="每日合计趋势">
        <DailyTrendLine days={days} height={280} />
      </Card>

      <div className="chart-grid">
        <Card title="事项占比">
          <ShareDonut items={tops} limit={8} height={300} />
        </Card>
        <Card title="事项 Top">
          {tops.length === 0 ? (
            <EmptyState
              title="该区间暂无事项"
              description="调整日期范围后再试。"
            />
          ) : (
            <HorizontalBars
              items={tops}
              height={Math.max(280, Math.min(tops.length, 12) * 36 + 40)}
            />
          )}
        </Card>
      </div>

      <Card title="Top 事项每日走势">
        <p className="mb-3 text-sm text-[var(--muted)]">
          区间内时长最多的 5 个事项
        </p>
        <TitleTrendLines series={trends} height={320} />
      </Card>

      <Card title="每日合计柱状">
        {days.every((d) => d.durationSec === 0) ? (
          <EmptyState title="该区间暂无每日合计" />
        ) : (
          <DailyTotalsBars days={days} />
        )}
      </Card>

      <Card title="明细">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[640px] text-left text-sm">
            <thead>
              <tr className="border-b border-[var(--border)] text-[var(--muted)]">
                <th className="pb-2 pr-3 font-medium">日期</th>
                <th className="pb-2 pr-3 font-medium">事项</th>
                <th className="pb-2 pr-3 font-medium">开始</th>
                <th className="pb-2 pr-3 font-medium">结束</th>
                <th className="pb-2 font-medium">时长</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={5}>
                    <EmptyState
                      title="该区间暂无记录"
                      description="换一个日期范围试试。"
                    />
                  </td>
                </tr>
              ) : (
                [...filtered].reverse().map((a) => (
                  <tr
                    key={a.id}
                    className="border-b border-[var(--border)]/60 last:border-0"
                  >
                    <td className="py-2 pr-3 tabular-nums">{a.dateLocal}</td>
                    <td className="py-2 pr-3 font-medium">{a.title}</td>
                    <td className="py-2 pr-3 tabular-nums">
                      {formatClock(a.start_at)}
                    </td>
                    <td className="py-2 pr-3 tabular-nums">
                      {a.ongoing ? "进行中" : formatClock(a.end_at!)}
                    </td>
                    <td className="py-2 tabular-nums">
                      {formatDuration(a.durationSec)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}

function PresetButton({
  children,
  onClick,
}: {
  children: React.ReactNode;
  onClick: () => void;
}) {
  return (
    <button type="button" onClick={onClick} className="btn-secondary text-sm">
      {children}
    </button>
  );
}
