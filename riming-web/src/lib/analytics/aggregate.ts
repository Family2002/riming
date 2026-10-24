import {
  addDays,
  endOfLocalDay,
  startOfLocalDay,
  toLocalDateKey,
} from "@/lib/analytics/format";
import type {
  Activity,
  ActivityWithDuration,
  DayTotal,
  HourBucket,
  MonthKpis,
  OverviewKpis,
  StackedDaily,
  TitleDaySeries,
  TitleTotal,
} from "@/lib/analytics/types";

export function durationSec(
  startAt: string,
  endAt: string | null,
  now = new Date(),
): number {
  const start = new Date(startAt).getTime();
  const end = endAt ? new Date(endAt).getTime() : now.getTime();
  return Math.max(0, Math.floor((end - start) / 1000));
}

/** Enrich rows; bucket by local calendar day of start_at (matches Flutter). */
export function withDuration(
  rows: Activity[],
  now = new Date(),
): ActivityWithDuration[] {
  return rows
    .filter((r) => !r.deleted_at)
    .map((r) => {
      const start = new Date(r.start_at);
      return {
        ...r,
        durationSec: durationSec(r.start_at, r.end_at, now),
        dateLocal: toLocalDateKey(start),
        ongoing: r.end_at == null,
      };
    })
    .sort(
      (a, b) =>
        new Date(a.start_at).getTime() - new Date(b.start_at).getTime(),
    );
}

export function totalDuration(items: { durationSec: number }[]): number {
  return items.reduce((sum, i) => sum + i.durationSec, 0);
}

export function topByTitle(
  items: ActivityWithDuration[],
  limit = 10,
): TitleTotal[] {
  const map = new Map<string, number>();
  for (const item of items) {
    map.set(item.title, (map.get(item.title) ?? 0) + item.durationSec);
  }
  return [...map.entries()]
    .map(([title, durationSec]) => ({ title, durationSec }))
    .sort((a, b) => b.durationSec - a.durationSec)
    .slice(0, limit);
}

export function dailyTotals(
  items: ActivityWithDuration[],
  from: Date,
  to: Date,
): DayTotal[] {
  const map = new Map<string, number>();
  let cursor = startOfLocalDay(from);
  const end = startOfLocalDay(to);
  while (cursor <= end) {
    map.set(toLocalDateKey(cursor), 0);
    cursor = addDays(cursor, 1);
  }
  for (const item of items) {
    if (map.has(item.dateLocal)) {
      map.set(item.dateLocal, (map.get(item.dateLocal) ?? 0) + item.durationSec);
    }
  }
  return [...map.entries()].map(([dateLocal, durationSec]) => ({
    dateLocal,
    durationSec,
  }));
}

/** Inclusive local-day range filter on start_at. */
export function filterByLocalDateRange(
  items: ActivityWithDuration[],
  from: Date,
  to: Date,
): ActivityWithDuration[] {
  const fromMs = startOfLocalDay(from).getTime();
  const toMs = endOfLocalDay(to).getTime();
  return items.filter((item) => {
    const t = new Date(item.start_at).getTime();
    return t >= fromMs && t <= toMs;
  });
}

export function filterByLocalDate(
  items: ActivityWithDuration[],
  day: Date,
): ActivityWithDuration[] {
  const key = toLocalDateKey(day);
  return items.filter((item) => item.dateLocal === key);
}

/** Distribute each activity's duration across local hours 0–23 by wall-clock overlap. */
export function hourHistogram(
  items: ActivityWithDuration[],
  now = new Date(),
): HourBucket[] {
  const buckets = Array.from({ length: 24 }, (_, hour) => ({
    hour,
    durationSec: 0,
  }));

  for (const item of items) {
    const startMs = new Date(item.start_at).getTime();
    const endMs = item.end_at ? new Date(item.end_at).getTime() : now.getTime();
    if (endMs <= startMs) continue;

    let cursor = startMs;
    while (cursor < endMs) {
      const d = new Date(cursor);
      const hourStart = new Date(
        d.getFullYear(),
        d.getMonth(),
        d.getDate(),
        d.getHours(),
      ).getTime();
      const hourEnd = hourStart + 3600_000;
      const sliceEnd = Math.min(endMs, hourEnd);
      const sec = Math.max(0, Math.floor((sliceEnd - cursor) / 1000));
      buckets[d.getHours()]!.durationSec += sec;
      cursor = sliceEnd;
    }
  }

  return buckets;
}

export function monthKpis(items: ActivityWithDuration[]): MonthKpis {
  const days = new Set<string>();
  const titles = new Set<string>();
  let totalSec = 0;
  for (const item of items) {
    days.add(item.dateLocal);
    titles.add(item.title);
    totalSec += item.durationSec;
  }
  const daysWithRecords = days.size;
  return {
    daysWithRecords,
    totalSec,
    avgPerDaySec:
      daysWithRecords > 0 ? Math.floor(totalSec / daysWithRecords) : 0,
    titleCount: titles.size,
  };
}

/** Daily duration series for each of the top N titles in the range. */
export function titleDailyTrends(
  items: ActivityWithDuration[],
  from: Date,
  to: Date,
  limit = 5,
): TitleDaySeries[] {
  const tops = topByTitle(items, limit);
  if (tops.length === 0) return [];

  const dayKeys: string[] = [];
  let cursor = startOfLocalDay(from);
  const end = startOfLocalDay(to);
  while (cursor <= end) {
    dayKeys.push(toLocalDateKey(cursor));
    cursor = addDays(cursor, 1);
  }

  return tops.map(({ title }) => {
    const map = new Map(dayKeys.map((k) => [k, 0]));
    for (const item of items) {
      if (item.title !== title) continue;
      if (!map.has(item.dateLocal)) continue;
      map.set(item.dateLocal, (map.get(item.dateLocal) ?? 0) + item.durationSec);
    }
    return {
      title,
      points: dayKeys.map((dateLocal) => ({
        dateLocal,
        durationSec: map.get(dateLocal) ?? 0,
      })),
    };
  });
}

/**
 * Daily stacked durations for top N titles; remainder folded into 「其他」.
 * Empty days keep zero columns so the axis stays contiguous.
 */
export function stackedDailyByTitle(
  items: ActivityWithDuration[],
  from: Date,
  to: Date,
  limit = 5,
): StackedDaily {
  const dayKeys: string[] = [];
  let cursor = startOfLocalDay(from);
  const end = startOfLocalDay(to);
  while (cursor <= end) {
    dayKeys.push(toLocalDateKey(cursor));
    cursor = addDays(cursor, 1);
  }

  const daySet = new Set(dayKeys);
  const tops = topByTitle(items, limit);
  const topSet = new Set(tops.map((t) => t.title));
  const titleOrder = tops.map((t) => t.title);

  const maps = new Map<string, Map<string, number>>();
  for (const title of titleOrder) {
    maps.set(title, new Map(dayKeys.map((k) => [k, 0])));
  }
  const otherMap = new Map(dayKeys.map((k) => [k, 0]));
  let hasOther = false;

  for (const item of items) {
    if (!daySet.has(item.dateLocal)) continue;
    if (topSet.has(item.title)) {
      const m = maps.get(item.title)!;
      m.set(item.dateLocal, (m.get(item.dateLocal) ?? 0) + item.durationSec);
    } else {
      hasOther = true;
      otherMap.set(
        item.dateLocal,
        (otherMap.get(item.dateLocal) ?? 0) + item.durationSec,
      );
    }
  }

  const series: StackedDaily["series"] = titleOrder.map((title) => ({
    title,
    valuesSec: dayKeys.map((k) => maps.get(title)!.get(k) ?? 0),
  }));

  if (hasOther) {
    series.push({
      title: "其他",
      valuesSec: dayKeys.map((k) => otherMap.get(k) ?? 0),
    });
  }

  return { days: dayKeys, series };
}

/** KPI strip for overview: month total, recent 7d, active days, title count. */
export function overviewKpis(
  monthItems: ActivityWithDuration[],
  weekItems: ActivityWithDuration[],
): OverviewKpis {
  const days = new Set<string>();
  const titles = new Set<string>();
  let monthTotalSec = 0;
  for (const item of monthItems) {
    days.add(item.dateLocal);
    titles.add(item.title);
    monthTotalSec += item.durationSec;
  }
  return {
    monthTotalSec,
    weekTotalSec: totalDuration(weekItems),
    activeDays: days.size,
    titleCount: titles.size,
  };
}

/** Occupancy fractions (0–1) per hour for a single local day strip. */
export function hourOccupancy(
  items: ActivityWithDuration[],
  dateKey: string,
  now = new Date(),
): number[] {
  const [y, m, d] = dateKey.split("-").map(Number);
  const dayStart = new Date(y, m - 1, d).getTime();
  const dayEnd = dayStart + 24 * 3600_000;
  const occupied = Array.from({ length: 24 }, () => 0);

  for (const item of items) {
    const startMs = Math.max(new Date(item.start_at).getTime(), dayStart);
    const rawEnd = item.end_at ? new Date(item.end_at).getTime() : now.getTime();
    const endMs = Math.min(rawEnd, dayEnd);
    if (endMs <= startMs) continue;

    let cursor = startMs;
    while (cursor < endMs) {
      const hour = Math.floor((cursor - dayStart) / 3600_000);
      const hourEnd = dayStart + (hour + 1) * 3600_000;
      const sliceEnd = Math.min(endMs, hourEnd);
      occupied[hour]! += Math.max(0, sliceEnd - cursor);
      cursor = sliceEnd;
    }
  }

  return occupied.map((ms) => Math.min(1, ms / 3600_000));
}
