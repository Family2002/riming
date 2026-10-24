import type { YAXisComponentOption } from "echarts";

/**
 * ECharts `containLabel` reserves tick-label space but not axis `name`.
 * Default `nameLocation: "end"` puts the unit above the plot; without enough
 * `grid.top` the glyphs clip against the canvas top edge.
 */
export const VALUE_AXIS_NAME_TOP = 44;

export const minutesValueAxis = {
  type: "value" as const,
  name: "分钟",
  nameLocation: "end" as const,
  nameGap: 8,
  nameTextStyle: {
    color: "#5a6e67",
    fontSize: 11,
    align: "left" as const,
    padding: [0, 0, 0, 0],
  },
  axisLabel: { color: "#5a6e67" },
  splitLine: { lineStyle: { color: "#d5e0db" } },
} satisfies YAXisComponentOption;
