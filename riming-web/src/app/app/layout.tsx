import { Suspense } from "react";

import { AppNavFallback } from "@/components/ui/AppNavFallback";
import { AppNavServer } from "@/components/ui/AppNavServer";

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <Suspense fallback={<AppNavFallback />}>
        <AppNavServer />
      </Suspense>
      <main className="mx-auto w-full max-w-6xl flex-1 px-4 py-5 sm:px-6 sm:py-6">
        {children}
      </main>
    </>
  );
}
