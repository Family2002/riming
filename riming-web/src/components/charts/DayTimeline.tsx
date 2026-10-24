"use client";

import type { EChartsOption } from "echarts";

import { EChart } from "@/components/charts/EChart";
import { EmptyState } from "@/components/ui/EmptyState";
import { formatClock, formatDuration } from "@/lib/analytics/format";
import type { ActivityWithDuration } from "@/lib/analytics/types";

type Props = {
  items: ActivityWithDuration[];
  dateKey: string;
  /** When true, skip the thin strip chart (used alongside DayHourStrip). */
  listOnly?: boolean;
};

/** Day segments: optional thin strip + ordered list. */
export function DayTimeline({ items, dateKey, listOnly = false }: Props) {
  if (items.length === 0) {
    return (
      <EmptyState
        title="这一天没有记录"
        description="用左右切换日期，或回总览从热力图选一天。"
      />
    );
  }

  const list = (
    <ul className="divide-y divide-[var(--border)]">
      {items.map((a) => (
        <li
          key={a.id}
          className="flex items-start justify-between gap-4 py-3.5 first:pt-1 last:pb-0"
        >
          <div>
            <p className="font-medium text-[var(--ink)]">{a.title}</p>
            <p className="mt-0.5 text-sm tabular-nums text-[var(--muted)]">
              {formatClock(a.start_at)}
              {" – "}
              {a.ongoing ? "进行中" : formatClock(a.end_at!)}
            </p>
          </div>
          <p className="shrink-0 text-sm tabular-nums text-[var(--muted)]">
            {formatDuration(a.durationSec)}
          </p>
        </li>
      ))}
    </ul>
  );

  if (listOnly) {
    return list;
  }

  const [y, m, d] = dateKey.split("-").map(Number);
  const dayStart = new Date(y, m - 1, d).getTime();
  const dayEnd = dayStart + 24 * 3600 * 1000;
  const now = Date.now();

  const segments = items.map((a) => {
    const startMs = Math.max(new Date(a.start_at).getTime(), dayStart);
    const rawEnd = a.end_at ? new Date(a.end_at).getTime() : now;
    const endMs = Math.min(rawEnd, dayEnd);
    return {
      title: a.title,
      startH: (startMs - dayStart) / 3600000,
      endH: Math.max(
        (endMs - dayStart) / 3600000,
        (startMs - dayStart) / 3600000 + 1 / 60,
      ),
      durationSec: a.durationSec,
      startLabel: formatClock(a.start_at),
      endLabel: a.ongoing ? "进行中" : formatClock(a.end_at!),
      ongoing: a.ongoing,
    };
  });

  const option: EChartsOption = {
    tooltip: {
      formatter: (params: unknown) => {
        const p = params as { data?: (typeof segments)[number] };
        const s = p?.data;
        if (!s) return "";
        return `${s.title}<br/>${s.startLabel} – ${s.endLabel}<br/>时长 ${formatDuration(s.durationSec)}`;
      },
    },
    grid: { left: 8, right: 40, top: 20, bottom: 32, containLabel: true },
    xAxis: {
      type: "value",
      min: 0,
      max: 24,
      interval: 4,
      name: "时刻",
      nameLocation: "end",
      nameGap: 8,
      nameTextStyle: { color: "#5a6e67", fontSize: 11, padding: [0, 0, 0, 6] },
      axisLabel: {
        color: "#5a6e67",
        formatter: (v: number) => `${String(v).padStart(2, "0")}:00`,
      },
      splitLine: { lineStyle: { color: "#d5e0db" } },
    },
    yAxis: {
      type: "category",
      data: ["当日"],
      axisLabel: { show: false },
      axisTick: { show: false },
      axisLine: { show: false },
    },
    series: [
      {
        type: "custom",
        renderItem: (_params, api) => {
          const start = api.value(0) as number;
          const end = api.value(1) as number;
          const cat = api.value(2) as number;
          const yBand = api.coord([0, cat]);
          const xStart = api.coord([start, cat]);
          const xEnd = api.coord([end, cat]);
          const height = (api.size?.([0, 1]) as number[])?.[1] ?? 28;
          const barH = Math.min(28, height * 0.55);
          return {
            type: "rect",
            shape: {
              x: xStart[0],
              y: yBand[1] - barH / 2,
              width: Math.max(xEnd[0] - xStart[0], 2),
              height: barH,
              r: 3,
            },
            style: {
              fill: "#1a6b5f",
              opacity: 0.88,
            },
          };
        },
        encode: { x: [0, 1], y: 2 },
        data: segments.map((s) => ({
          value: [s.startH, s.endH, 0],
          ...s,
        })),
      },
    ],
  };

  return (
    <div>
      <EChart option={option} height={110} />
      <div className="mt-4">{list}</div>
    </div>
  );
}
