import { connection } from "next/server";

import { withDuration } from "@/lib/analytics/aggregate";
import type { ActivityWithDuration } from "@/lib/analytics/types";
import { createClient } from "@/lib/supabase/server";
import type { ActivityRow } from "@/lib/types/database";

export type ActivitiesResult =
  | { ok: true; items: ActivityWithDuration[] }
  | { ok: false; error: string };

/**
 * Fetch non-deleted activities for the signed-in user.
 * Optional ISO bounds on start_at (inclusive lower, exclusive upper preferred).
 *
 * Day analytics elsewhere bucket by the **local calendar day of start_at**
 * (same as Flutter). Ongoing rows use duration to "now".
 */
export async function fetchActivities(opts?: {
  fromIso?: string;
  toIso?: string;
}): Promise<ActivitiesResult> {
  await connection();
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError) {
    return { ok: false, error: "无法验证登录状态，请重新登录" };
  }
  if (!user) {
    return { ok: false, error: "未登录" };
  }

  let query = supabase
    .from("activities")
    .select("id,user_id,title,start_at,end_at,updated_at,deleted_at")
    .is("deleted_at", null)
    .order("start_at", { ascending: true });

  if (opts?.fromIso) {
    query = query.gte("start_at", opts.fromIso);
  }
  if (opts?.toIso) {
    query = query.lt("start_at", opts.toIso);
  }

  const { data, error } = await query;
  if (error) {
    return { ok: false, error: error.message || "读取活动失败" };
  }
  return {
    ok: true,
    items: withDuration((data ?? []) as ActivityRow[]),
  };
}
