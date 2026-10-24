"use client";

import type { EChartsOption } from "echarts";

import { EChart } from "@/components/charts/EChart";
import { EmptyState } from "@/components/ui/EmptyState";
import { formatDuration } from "@/lib/analytics/format";
import type { TitleTotal } from "@/lib/analytics/types";

type Props = {
  items: TitleTotal[];
  height?: number;
};

export function HorizontalBars({ items, height }: Props) {
  const titles = items.map((i) => i.title).reverse();
  const values = items.map((i) => Math.round(i.durationSec / 60)).reverse();
  const chartHeight = height ?? Math.max(200, items.length * 34 + 36);

  const option: EChartsOption = {
    tooltip: {
      trigger: "axis",
      axisPointer: { type: "shadow" },
      formatter: (params: unknown) => {
        const list = params as { name: string; value: number }[];
        const p = list?.[0];
        if (!p) return "";
        return `${p.name}<br/>时长 ${formatDuration(p.value * 60)}`;
      },
    },
    grid: { left: 8, right: 64, top: 8, bottom: 8, containLabel: true },
    xAxis: {
      type: "value",
      name: "分钟",
      nameGap: 8,
      nameTextStyle: { color: "#5a6e67", fontSize: 11, padding: [0, 0, 0, 4] },
      axisLabel: {
        color: "#5a6e67",
        formatter: (v: number) => `${v}`,
      },
      splitLine: { lineStyle: { color: "#d5e0db" } },
    },
    yAxis: {
      type: "category",
      data: titles,
      axisLabel: { color: "#14241f", width: 120, overflow: "truncate" },
      axisTick: { show: false },
      axisLine: { show: false },
    },
    series: [
      {
        type: "bar",
        data: values,
        barMaxWidth: 22,
        itemStyle: {
          color: "#1a6b5f",
          borderRadius: [0, 3, 3, 0],
        },
        label: {
          show: true,
          position: "right",
          color: "#5a6e67",
          formatter: (p) => {
            const v = typeof p.value === "number" ? p.value : 0;
            return formatDuration(v * 60);
          },
        },
      },
    ],
  };

  if (items.length === 0) {
    return (
      <EmptyState
        title="暂无事项"
        description="换一个月或日期范围，或在手机端先记一笔。"
      />
    );
  }

  return <EChart option={option} height={chartHeight} />;
}
