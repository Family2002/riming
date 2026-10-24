import type { ActivityWithDuration } from "@/lib/analytics/types";

function escapeCsv(value: string): string {
  if (/[",\n\r]/.test(value)) {
    return `"${value.replace(/"/g, '""')}"`;
  }
  return value;
}

/** Columns: id,title,start_at,end_at,duration_sec,date_local */
export function activitiesToCsv(items: ActivityWithDuration[]): string {
  const header = "id,title,start_at,end_at,duration_sec,date_local";
  const lines = items.map((a) =>
    [
      a.id,
      escapeCsv(a.title),
      a.start_at,
      a.end_at ?? "",
      String(a.durationSec),
      a.dateLocal,
    ].join(","),
  );
  return [header, ...lines].join("\n");
}

export function downloadCsv(filename: string, csv: string) {
  const blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
