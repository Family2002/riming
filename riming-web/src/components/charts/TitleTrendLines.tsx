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
import type { TitleDaySeries } from "@/lib/analytics/types";

const PALETTE = ["#1a6b5f", "#3d8f82", "#14574d", "#6ba89c", "#0f3f38"];

type Props = {
  series: TitleDaySeries[];
  height?: number;
};

export function TitleTrendLines({ series, height = 300 }: Props) {
  if (series.length === 0) {
    return (
      <EmptyState
        title="暂无事项趋势"
        description="区间内有多项记录后，会显示 Top 事项的每日时长走势。"
      />
    );
  }

  const dates = series[0]!.points.map((p) => p.dateLocal);
  const dense = dates.length > 14;

  const option: EChartsOption = {
    color: PALETTE,
    tooltip: {
      trigger: "axis",
      formatter: (params: unknown) => {
        const list = params as {
          seriesName: string;
          value: number;
          dataIndex: number;
          marker: string;
        }[];
        if (!list?.length) return "";
        const date = dates[list[0]!.dataIndex];
        const head = date ? formatDateShortZh(date) : "";
        const lines = list
          .map(
            (p) =>
              `${p.marker}${p.seriesName}：${formatDuration(p.value * 60)}`,
          )
          .join("<br/>");
        return `${head}<br/>${lines}`;
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
      data: dates.map((d) => formatDateShortZh(d)),
      axisLabel: {
        color: "#5a6e67",
        rotate: dense ? 45 : 0,
        fontSize: dense ? 11 : 12,
        interval: dense ? "auto" : 0,
      },
      axisTick: { show: false },
    },
    yAxis: minutesValueAxis,
    series: series.map((s) => ({
      name: s.title,
      type: "line" as const,
      smooth: true,
      showSymbol: dates.length <= 14,
      symbolSize: 6,
      lineStyle: { width: 2.5 },
      data: s.points.map((p) => Math.round(p.durationSec / 60)),
    })),
  };

  return <EChart option={option} height={height} />;
}
