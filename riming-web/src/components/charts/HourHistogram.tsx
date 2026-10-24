"use client";

import type { EChartsOption } from "echarts";

import { EChart } from "@/components/charts/EChart";
import {
  VALUE_AXIS_NAME_TOP,
  minutesValueAxis,
} from "@/components/charts/chartLayout";
import { EmptyState } from "@/components/ui/EmptyState";
import { formatDuration } from "@/lib/analytics/format";
import type { HourBucket } from "@/lib/analytics/types";

type Props = {
  buckets: HourBucket[];
  height?: number;
};

export function HourHistogram({ buckets, height = 260 }: Props) {
  const total = buckets.reduce((s, b) => s + b.durationSec, 0);
  if (total <= 0) {
    return (
      <EmptyState
        title="暂无时段数据"
        description="有记录后可看出一天里哪些小时更常记事。"
      />
    );
  }

  const labels = buckets.map((b) => `${String(b.hour).padStart(2, "0")}`);
  const values = buckets.map((b) => Math.round(b.durationSec / 60));

  const option: EChartsOption = {
    tooltip: {
      trigger: "axis",
      formatter: (params: unknown) => {
        const list = params as { name: string; value: number }[];
        const p = list?.[0];
        if (!p) return "";
        const hour = Number(p.name);
        const next = String((hour + 1) % 24).padStart(2, "0");
        return `${p.name}:00 – ${next}:00<br/>合计 ${formatDuration(p.value * 60)}`;
      },
    },
    grid: {
      left: 12,
      right: 28,
      top: VALUE_AXIS_NAME_TOP,
      bottom: 28,
      containLabel: true,
    },
    xAxis: {
      type: "category",
      data: labels,
      name: "时",
      nameGap: 8,
      nameTextStyle: { color: "#5a6e67", fontSize: 11 },
      axisLabel: {
        color: "#5a6e67",
        fontSize: 11,
        interval: 1,
      },
      axisTick: { show: false },
    },
    yAxis: minutesValueAxis,
    series: [
      {
        type: "bar",
        data: values,
        barMaxWidth: 18,
        itemStyle: {
          color: "#3d8f82",
          borderRadius: [2, 2, 0, 0],
        },
      },
    ],
  };

  return <EChart option={option} height={height} />;
}
