import type { ActivityRow } from "@/lib/types/database";

export type Activity = ActivityRow;

export type ActivityWithDuration = Activity & {
  durationSec: number;
  dateLocal: string;
  ongoing: boolean;
};

export type TitleTotal = {
  title: string;
  durationSec: number;
};

export type DayTotal = {
  dateLocal: string;
  durationSec: number;
};

export type HourBucket = {
  hour: number; // 0–23
  durationSec: number;
};

export type MonthKpis = {
  daysWithRecords: number;
  totalSec: number;
  avgPerDaySec: number;
  titleCount: number;
};

export type TitleDaySeries = {
  title: string;
  points: DayTotal[];
};

/** Stacked daily bars: top titles (+ optional 其他) across a date range. */
export type StackedDaily = {
  days: string[];
  series: { title: string; valuesSec: number[] }[];
};

export type OverviewKpis = {
  monthTotalSec: number;
  weekTotalSec: number;
  activeDays: number;
  titleCount: number;
};
