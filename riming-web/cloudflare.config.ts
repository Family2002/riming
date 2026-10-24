import { bindings, defineConfig, defineWorker } from "cf/config";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "";

export default defineConfig({
  worker: defineWorker({
    name: "riming-web",
    entrypoint: "vinext/server/fetch-handler",
    compatibilityDate: "2026-10-24",
    compatibilityFlags: ["nodejs_compat"],
    assets: {
      htmlHandling: "none",
      notFoundHandling: "none",
      runWorkerFirst: ["/*", "!/_next/static/*", "!/*/_next/static/*"],
    },
    workersDev: true,
    previewUrls: true,
    // Zone shilongs.top must be Active on this account (NS: bruce/holly).
    domains: ["riming.shilongs.top"],
    env: {
      ASSETS: bindings.assets(),
      IMAGES: bindings.images(),
      VINEXT_KV_CACHE: bindings.kv({ id: "be64622b20d94e9f837ffe5e627a93d7" }),
      // Public client keys — values come from .env.local / CI env at deploy time.
      NEXT_PUBLIC_SUPABASE_URL: bindings.text(supabaseUrl),
      NEXT_PUBLIC_SUPABASE_ANON_KEY: bindings.text(supabaseAnonKey),
    },
  }),
});
