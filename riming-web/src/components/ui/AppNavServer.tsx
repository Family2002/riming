import { connection } from "next/server";

import { AppNav } from "@/components/ui/AppNav";
import { createClient } from "@/lib/supabase/server";

export async function AppNavServer() {
  await connection();
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  return <AppNav email={user?.email} />;
}
