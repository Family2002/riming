"use client";

import { useRouter } from "next/navigation";
import type { EChartsOption } from "echarts";

import { EChart } from "@/components/charts/EChart";
import {
  formatDateShortZh,
  formatDuration,
} from "@/lib/analytics/format";
import type { DayTotal } from "@/lib/analytics/types";

type Props = {
  year: number;
  month: number; // 1-12
  days: DayTotal[];
};

export function MonthHeatmap({ year, month, days }: Props) {
  const router = useRouter();
  const start = `${year}-${String(month).padStart(2, "0")}-01`;
  const lastDay = new Date(year, month, 0).getDate();
  const end = `${year}-${String(month).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;
  const data = days.map(
    (d) => [d.dateLocal, Math.round(d.durationSec / 60)] as [string, number],
  );
  const peak = Math.max(0, ...data.map((d) => d[1]));
  const max = Math.max(1, peak);
  const hasActivity = peak > 0;

  const option: EChartsOption = {
    tooltip: {
      formatter: (params: unknown) => {
        const p = params as { data?: [string, number] };
        if (!p?.data) return "";
        const [date, minutes] = p.data;
        return `${formatDateShortZh(date)}<br/>合计 ${formatDuration(minutes * 60)}<br/><span style="color:#5a6e67">点击查看当日</span>`;
      },
    },
    visualMap: {
      min: 0,
      max,
      show: hasActivity,
      calculable: false,
      orient: "horizontal",
      left: "center",
      bottom: 0,
      inRange: {
        color: ["#e8f0ed", "#9ec9bf", "#4a9a8a", "#14574d"],
      },
      text: ["较多", "较少"],
      textStyle: { color: "#5a6e67", fontSize: 12 },
      formatter: ((v: unknown) => {
        const n = typeof v === "number" ? v : Number(v);
        if (!Number.isFinite(n) || n <= 0) return "0分";
        return `${Math.round(n)}分`;
      }) as never,
    },
    calendar: {
      top: 36,
      left: 44,
      right: 20,
      bottom: hasActivity ? 56 : 16,
      cellSize: ["auto", 28],
      range: [start, end],
      itemStyle: {
        borderWidth: 4,
        borderColor: "#f8fbf9",
      },
      yearLabel: { show: false },
      monthLabel: { show: false },
      dayLabel: {
        nameMap: ["日", "一", "二", "三", "四", "五", "六"],
        color: "#5a6e67",
        fontSize: 12,
      },
      splitLine: { show: false },
    },
    series: [
      {
        type: "heatmap",
        coordinateSystem: "calendar",
        data,
        emphasis: {
          itemStyle: {
            shadowBlur: 6,
            shadowColor: "rgba(20, 36, 31, 0.25)",
          },
        },
      },
    ],
  };

  return (
    <EChart
      option={option}
      height={300}
      onEvents={{
        click: (params: unknown) => {
          const p = params as { data?: [string, number] };
          if (p?.data?.[0]) {
            router.push(`/app/day/${p.data[0]}`);
          }
        },
      }}
    />
  );
}
