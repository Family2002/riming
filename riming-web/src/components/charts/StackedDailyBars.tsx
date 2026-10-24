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
import type { StackedDaily } from "@/lib/analytics/types";

const PALETTE = [
  "#14574d",
  "#1a6b5f",
  "#3d8f82",
  "#6ba89c",
  "#9ec9bf",
  "#b8cfc8",
];

type Props = {
  data: StackedDaily;
  height?: number;
};

export function StackedDailyBars({ data, height = 300 }: Props) {
  const hasData = data.series.some((s) => s.valuesSec.some((v) => v > 0));
  if (!hasData || data.days.length === 0) {
    return (
      <EmptyState
        title="近 7 天暂无数据"
        description="有记录后会显示按事项堆叠的每日时长。"
      />
    );
  }

  const labels = data.days.map((d) => formatDateShortZh(d));
  const dense = data.days.length > 14;

  const option: EChartsOption = {
    color: PALETTE,
    tooltip: {
      trigger: "axis",
      axisPointer: { type: "shadow" },
      formatter: (params: unknown) => {
        const list = params as {
          seriesName: string;
          value: number;
          dataIndex: number;
          marker: string;
        }[];
        if (!list?.length) return "";
        const date = data.days[list[0]!.dataIndex];
        const head = date ? formatDateShortZh(date) : "";
        const lines = list
          .filter((p) => p.value > 0)
          .map(
            (p) =>
              `${p.marker}${p.seriesName}：${formatDuration(p.value * 60)}`,
          );
        const totalMin = list.reduce((s, p) => s + (p.value || 0), 0);
        return `${head}<br/>合计 ${formatDuration(totalMin * 60)}<br/>${lines.join("<br/>")}`;
      },
    },
    legend: {
      type: "scroll",
      bottom: 0,
      textStyle: { color: "#5a6e67", fontSize: 12 },
      pageTextStyle: { color: "#5a6e67" },
    },
    grid: {
      left: 12,
      right: 16,
      top: VALUE_AXIS_NAME_TOP,
      bottom: 48,
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
    yAxis: minutesValueAxis,
    series: data.series.map((s) => ({
      name: s.title,
      type: "bar" as const,
      stack: "total",
      barMaxWidth: 28,
      emphasis: { focus: "series" as const },
      data: s.valuesSec.map((sec) => Math.round(sec / 60)),
    })),
  };

  return <EChart option={option} height={height} />;
}
