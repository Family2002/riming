"use client";

import type { EChartsOption } from "echarts";

import { EChart } from "@/components/charts/EChart";
import {
  VALUE_AXIS_NAME_TOP,
  minutesValueAxis,
} from "@/components/charts/chartLayout";
import { EmptyState } from "@/components/ui/EmptyState";
import {
  formatDateShortZh,
  formatDuration,
} from "@/lib/analytics/format";
import type { DayTotal } from "@/lib/analytics/types";

type Props = {
  days: DayTotal[];
  height?: number;
};

/** Single-series daily total duration trend. */
export function DailyTrendLine({ days, height = 280 }: Props) {
  if (days.length === 0 || days.every((d) => d.durationSec === 0)) {
    return (
      <EmptyState
        title="暂无每日趋势"
        description="该区间有记录后，会显示合计时长走势。"
      />
    );
  }

  const labels = days.map((d) => formatDateShortZh(d.dateLocal));
  const values = days.map((d) => Math.round(d.durationSec / 60));
  const dense = days.length > 14;

  const option: EChartsOption = {
    tooltip: {
      trigger: "axis",
      formatter: (params: unknown) => {
        const list = params as {
          name: string;
          value: number;
          dataIndex: number;
        }[];
        const p = list?.[0];
        if (!p) return "";
        const full = days[p.dataIndex]?.dateLocal;
        const label = full ? formatDateShortZh(full) : p.name;
        return `${label}<br/>合计 ${formatDuration(p.value * 60)}`;
      },
    },
    grid: {
      left: 12,
      right: 16,
      top: VALUE_AXIS_NAME_TOP,
      bottom: dense ? 40 : 28,
      containLabel: true,
    },
    xAxis: {
      type: "category",
      data: labels,
      boundaryGap: false,
      axisLabel: {
        color: "#5a6e67",
        rotate: dense ? 45 : 0,
        fontSize: dense ? 11 : 12,
        interval: dense ? "auto" : 0,
      },
      axisTick: { show: false },
    },
    yAxis: minutesValueAxis,
    series: [
      {
        type: "line",
        smooth: true,
        showSymbol: days.length <= 14,
        symbolSize: 6,
        lineStyle: { width: 2.5, color: "#1a6b5f" },
        itemStyle: { color: "#1a6b5f" },
        areaStyle: {
          color: {
            type: "linear",
            x: 0,
            y: 0,
            x2: 0,
            y2: 1,
            colorStops: [
              { offset: 0, color: "rgba(26, 107, 95, 0.28)" },
              { offset: 1, color: "rgba(26, 107, 95, 0.02)" },
            ],
          },
        },
        data: values,
      },
    ],
  };

  return <EChart option={option} height={height} />;
}
