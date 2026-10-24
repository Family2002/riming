"use client";

import type { EChartsOption } from "echarts";

import { EChart } from "@/components/charts/EChart";
import { EmptyState } from "@/components/ui/EmptyState";
import { formatDuration } from "@/lib/analytics/format";
import type { TitleTotal } from "@/lib/analytics/types";

const PALETTE = [
  "#14574d",
  "#1a6b5f",
  "#3d8f82",
  "#4a9a8a",
  "#6ba89c",
  "#9ec9bf",
  "#b8cfc8",
  "#c2d0ca",
];

type Props = {
  items: TitleTotal[];
  /** Fold titles beyond this into 「其他」. */
  limit?: number;
  height?: number;
};

export function ShareDonut({ items, limit = 8, height = 300 }: Props) {
  if (items.length === 0) {
    return (
      <EmptyState
        title="暂无事项占比"
        description="该区间有记录后，会显示事项时长构成。"
      />
    );
  }

  const top = items.slice(0, limit);
  const rest = items.slice(limit);
  const otherSec = rest.reduce((s, i) => s + i.durationSec, 0);
  const slices = [...top];
  if (otherSec > 0) {
    slices.push({ title: "其他", durationSec: otherSec });
  }

  const total = slices.reduce((s, i) => s + i.durationSec, 0);

  const option: EChartsOption = {
    color: PALETTE,
    tooltip: {
      trigger: "item",
      formatter: (params: unknown) => {
        const p = params as {
          name: string;
          value: number;
          percent: number;
        };
        return `${p.name}<br/>${formatDuration(p.value)}（${p.percent.toFixed(1)}%）`;
      },
    },
    legend: {
      type: "scroll",
      orient: "vertical",
      right: 0,
      top: "middle",
      textStyle: { color: "#5a6e67", fontSize: 12 },
      pageTextStyle: { color: "#5a6e67" },
    },
    series: [
      {
        type: "pie",
        radius: ["42%", "68%"],
        center: ["38%", "50%"],
        avoidLabelOverlap: true,
        itemStyle: {
          borderRadius: 3,
          borderColor: "#f8fbf9",
          borderWidth: 2,
        },
        label: {
          show: false,
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 13,
            fontWeight: 600,
            color: "#14241f",
            formatter: (p) => {
              const name = String(p.name ?? "");
              const pct = typeof p.percent === "number" ? p.percent : 0;
              return `${name}\n${pct.toFixed(0)}%`;
            },
          },
        },
        data: slices.map((s) => ({
          name: s.title,
          value: s.durationSec,
        })),
      },
    ],
    graphic: [
      {
        type: "text",
        left: "30%",
        top: "46%",
        style: {
          text: "合计",
          fill: "#5a6e67",
          fontSize: 12,
          align: "center",
        },
      },
      {
        type: "text",
        left: "30%",
        top: "52%",
        style: {
          text: formatDuration(total),
          fill: "#14241f",
          fontSize: 13,
          fontWeight: 600,
          align: "center",
        },
      },
    ],
  };

  return <EChart option={option} height={height} />;
}
