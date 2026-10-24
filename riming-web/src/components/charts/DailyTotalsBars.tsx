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
};

export function DailyTotalsBars({ days }: Props) {
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
      left: 16,
      right: 16,
      top: VALUE_AXIS_NAME_TOP,
      bottom: dense ? 40 : 28,
      containLabel: true,
    },
    xAxis: {
      type: "category",
      data: labels,
      axisLabel: {
        color: "#5a6e67",
        rotate: dense ? 45 : 0,
        fontSize: dense ? 11 : 12,
        interval: dense ? "auto" : 0,
      },
      axisTick: { show: false },
    },
    yAxis: {
      ...minutesValueAxis,
      axisLabel: {
        color: "#5a6e67",
        formatter: (v: number) => `${v}`,
      },
    },
    series: [
      {
        type: "bar",
        data: values,
        barMaxWidth: 28,
        itemStyle: {
          color: "#3d8f82",
          borderRadius: [3, 3, 0, 0],
        },
      },
    ],
  };

  if (days.length === 0) {
    return (
      <EmptyState
        title="暂无每日合计"
        description="调整上方日期后再看。"
      />
    );
  }

  return <EChart option={option} height={300} />;
}
