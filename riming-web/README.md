# 日铭 · 网页分析（`riming-web/`）

本目录是 **日铭 monorepo** 中的网页分析端：手机 App 负责记录；本站提供热力图、当日明细、区间统计与 CSV 导出。登录账号与日铭 App 相同（邮箱 + 密码）。

**访问地址**

| 用途 | 地址 |
|------|------|
| **正式 / 预期域名** | [https://riming.shilongs.top](https://riming.shilongs.top) |
| 过渡（Cloudflare Workers） | [https://riming-web.wylking.workers.dev](https://riming-web.wylking.workers.dev) |

许可证与致谢见仓库根目录 [`LICENSE`](../LICENSE) / [`NOTICE`](../NOTICE) / [`README.md`](../README.md)（PolyForm Noncommercial）。

## 本地运行

1. 安装依赖：

```bash
cd riming-web
npm install
```

2. 配置环境变量：复制 `.env.local.example` 为 `.env.local`，填入你的 Supabase **Project URL** 与 **anon key**（Dashboard → Project Settings → API）。切勿提交 `.env.local`。

```bash
cp .env.local.example .env.local
```

```env
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

3. 启动开发服务器：

```bash
npm run dev
```

浏览器打开 [http://localhost:3000](http://localhost:3000)。

## 页面

| 路径 | 说明 |
|------|------|
| `/login` | 登录 / 注册（与 App 相同邮箱；若开启邮箱确认会提示先验证） |
| `/app` | 月热力图 + 近 7 天摘要 + 本月 Top |
| `/app/day/[date]` | 当日横向柱图 + 时间线（`date` 为本地 `YYYY-MM-DD`） |
| `/app/range` | 日期区间、图表、明细表、导出 CSV |

CSV 列：`id,title,start_at,end_at,duration_sec,date_local`

## 部署（可选）

- **任意 Node 托管**：导入本目录，设置与 `.env.local` 相同的两个 `NEXT_PUBLIC_*` 变量。
- **Cloudflare Workers（vinext）**：本目录已含 `vite.config.ts` 与 `cloudflare.config.ts`。配置好环境变量后执行：

```bash
npm run deploy:vinext
```

生产环境请在 Auth 中把站点 URL / Redirect URLs 配成 `https://riming.shilongs.top`（过渡期可同时保留 workers.dev）。不要把密钥写进 README 或提交进 git。

## 技术栈

Next.js（App Router）· vinext / Vite · TypeScript · Tailwind CSS · ECharts · Supabase JS（`@supabase/ssr`）· Cloudflare Workers（可选）
