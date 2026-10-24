"use client";

import type { EChartsOption } from "echarts";

import { EChart } from "@/components/charts/EChart";
import { EmptyState } from "@/components/ui/EmptyState";
import { formatClock, formatDuration } from "@/lib/analytics/format";
import type { ActivityWithDuration } from "@/lib/analytics/types";
import { hourOccupancy } from "@/lib/analytics/aggregate";

type Props = {
  items: ActivityWithDuration[];
  dateKey: string;
};

/** Dense 24h occupancy strip + multi-lane swim for the day. */
export function DayHourStrip({ items, dateKey }: Props) {
  if (items.length === 0) {
    return (
      <EmptyState
        title="这一天没有记录"
        description="用左右切换日期，或回总览从热力图选一天。"
      />
    );
  }

  const occupancy = hourOccupancy(items, dateKey);
  const [y, m, d] = dateKey.split("-").map(Number);
  const dayStart = new Date(y, m - 1, d).getTime();
  const dayEnd = dayStart + 24 * 3600_000;
  const now = Date.now();

  const lanes = items.map((a, index) => {
    const startMs = Math.max(new Date(a.start_at).getTime(), dayStart);
    const rawEnd = a.end_at ? new Date(a.end_at).getTime() : now;
    const endMs = Math.min(rawEnd, dayEnd);
    return {
      index,
      title: a.title,
      startH: (startMs - dayStart) / 3600_000,
      endH: Math.max(
        (endMs - dayStart) / 3600_000,
        (startMs - dayStart) / 3600_000 + 1 / 60,
      ),
      durationSec: a.durationSec,
      startLabel: formatClock(a.start_at),
      endLabel: a.ongoing ? "进行中" : formatClock(a.end_at!),
      ongoing: a.ongoing,
    };
  });

  const laneCount = Math.min(lanes.length, 12);
  const shown = lanes.slice(0, laneCount);
  const swimHeight = Math.max(140, laneCount * 28 + 48);

  const stripOption: EChartsOption = {
    tooltip: {
      formatter: (params: unknown) => {
        const p = params as { dataIndex?: number; value?: number };
        const hour = p?.dataIndex ?? 0;
        const frac = occupancy[hour] ?? 0;
        const mins = Math.round(frac * 60);
        return `${String(hour).padStart(2, "0")}:00 时段<br/>占用约 ${mins} 分钟`;
      },
    },
    grid: { left: 8, right: 8, top: 8, bottom: 22, containLabel: true },
    xAxis: {
      type: "category",
      data: Array.from({ length: 24 }, (_, i) => String(i).padStart(2, "0")),
      axisLabel: {
        color: "#5a6e67",
        fontSize: 10,
        interval: 1,
      },
      axisTick: { show: false },
      axisLine: { show: false },
    },
    yAxis: {
      type: "value",
      min: 0,
      max: 1,
      show: false,
    },
    series: [
      {
        type: "bar",
        data: occupancy.map((v) => ({
          value: v,
          itemStyle: {
            color:
              v <= 0
                ? "#e8f0ed"
                : v < 0.35
                  ? "#9ec9bf"
                  : v < 0.7
                    ? "#4a9a8a"
                    : "#14574d",
            borderRadius: [2, 2, 0, 0],
          },
        })),
        barCategoryGap: "8%",
      },
    ],
  };

  const swimOption: EChartsOption = {
    tooltip: {
      formatter: (params: unknown) => {
        const p = params as { data?: (typeof shown)[number] };
        const s = p?.data;
        if (!s) return "";
        return `${s.title}<br/>${s.startLabel} – ${s.endLabel}<br/>时长 ${formatDuration(s.durationSec)}`;
      },
    },
    grid: { left: 72, right: 12, top: 8, bottom: 28, containLabel: false },
    xAxis: {
      type: "value",
      min: 0,
      max: 24,
      interval: 4,
      axisLabel: {
        color: "#5a6e67",
        formatter: (v: number) => `${String(v).padStart(2, "0")}:00`,
      },
      splitLine: { lineStyle: { color: "#d5e0db" } },
    },
    yAxis: {
      type: "category",
      data: shown.map((s) => s.title).reverse(),
      axisLabel: {
        color: "#14241f",
        width: 64,
        overflow: "truncate",
        fontSize: 11,
      },
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
          const height = (api.size?.([0, 1]) as number[])?.[1] ?? 22;
          const barH = Math.min(18, height * 0.6);
          return {
            type: "rect",
            shape: {
              x: xStart[0],
              y: yBand[1] - barH / 2,
              width: Math.max(xEnd[0] - xStart[0], 3),
              height: barH,
              r: 3,
            },
            style: {
              fill: "#1a6b5f",
              opacity: 0.9,
            },
          };
        },
        encode: { x: [0, 1], y: 2 },
        data: shown.map((s, i) => ({
          value: [s.startH, s.endH, shown.length - 1 - i],
          ...s,
        })),
      },
    ],
  };

  return (
    <div className="space-y-4">
      <div>
        <p className="mb-1.5 text-xs text-[var(--muted)]">小时占用</p>
        <EChart option={stripOption} height={88} />
      </div>
      <div>
        <p className="mb-1.5 text-xs text-[var(--muted)]">事项泳道</p>
        <EChart option={swimOption} height={swimHeight} />
        {lanes.length > laneCount ? (
          <p className="mt-1 text-xs text-[var(--muted)]">
            仅展示前 {laneCount} 段，完整列表见下方时间线。
          </p>
        ) : null}
      </div>
    </div>
  );
}
