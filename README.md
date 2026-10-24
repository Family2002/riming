# 日铭（Riming）

**手机 App 负责记录，网页负责分析。**

- **手机（Flutter）**：点一下大按钮 → 输入事项 → 再点一下结束并切换下一项；数据保存在本机 SQLite，可选云同步。界面为 Material 3 + 液态玻璃风格。
- **网页（`riming-web/`）**：同一账号登录后查看热力图、当日明细、区间统计与 CSV 导出。

[English summary](#english) · [下载 APK](https://github.com/Family2002/riming/releases/tag/v1.0.2)

## 功能概览

- 一键开始 / 切换 / 结束事项，时间线自动分段
- 往日记录浏览、事项编辑与轻量当日摘要
- 多套安静日记感主题配色（浅色 / 深色 / 跟随系统）
- Android 前台服务常驻通知，后台计时不断档
- 可选**云同步 / 账号备份**（邮箱登录后多设备同步）
- **网页分析**：热力图、区间统计、CSV 导出（与 App 同一账号）

## 下载

正式预览包见 GitHub **[Releases v1.0.2](https://github.com/Family2002/riming/releases/tag/v1.0.2)**。

> APK 使用 Flutter 默认 **debug/preview 签名**（未配置独立 release keystore），仅供非商业试用；上架商店前请自行配置正式签名。

## 网页访问

| 用途 | 地址 |
|------|------|
| **正式 / 预期域名** | [https://riming.shilongs.top](https://riming.shilongs.top) |
| 过渡（Cloudflare Workers） | [https://riming-web.wylking.workers.dev](https://riming-web.wylking.workers.dev) |

登录账号与手机 App 相同（邮箱 + 密码）。生产环境请在你的后端 Auth 中把站点 URL / Redirect URLs 配成上述域名。

## 仓库结构

| 路径 | 说明 |
|------|------|
| `lib/`、`android/` … | Flutter 手机 App（采集 / 时间线） |
| [`riming-web/`](riming-web/) | 网页分析（Next.js / vinext → Cloudflare Workers） |

## 运行与构建

### Flutter 手机 App

```bash
flutter pub get
flutter devices
flutter run -d <deviceId>

# Release APK
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

可选云同步：复制 `.env.example` 为 `.env`，填入你自己的后端 **URL** 与 **anon/publishable key**，再用 `tools/run_with_env.ps1` 注入 `--dart-define`（切勿提交 `.env`）。

首次改库表结构后需重新生成 Drift 代码：

```bash
dart run build_runner build
```

Windows 请保证 `flutter`、`adb` 在 PATH，并设置 `ANDROID_HOME`。

### 网页分析（`riming-web/`）

详见 [`riming-web/README.md`](riming-web/README.md)。简要步骤：

```bash
cd riming-web
npm install
cp .env.local.example .env.local   # 填入你自己的 Project URL 与 anon key
npm run dev                        # http://localhost:3000
```

部署到 Cloudflare Workers（vinext）：

```bash
cd riming-web
npm run deploy:vinext
```

预期自定义域名为 `riming.shilongs.top`（见 `riming-web/cloudflare.config.ts`）；过渡可用 `riming-web.wylking.workers.dev`。不要把 `.env.local` 或密钥提交进仓库。

## 使用流程（手机）

1. 打开 App，点中间的「开始记录」
2. 输入当前事项（如「起床」）
3. 做完后点「切换事项」，输入下一件事；上一段会自动记上结束时间
4. 需要只结束、不开始下一项时，点「结束当前」
5. 点时间线上的事项可编辑名称与起止时间
6. 右上角可切换主题、账号同步；日历可查看往日时间线
7. 需要深度统计时，用同一账号打开网页端

## 技术栈

- **App**：Flutter · Material 3 · Riverpod · Drift (SQLite) · go_router · Google Fonts · flutter_foreground_task · [liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets)
- **Web**：Next.js（App Router）· vinext / Vite · TypeScript · Tailwind · ECharts · Cloudflare Workers（可选）

## 致谢 / Credits

开发过程中由 **Cursor**、**Grok** 作为 AI 协作者参与实现与迭代。

液态玻璃 UI 使用开源库 **[liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets)**（请遵循该仓库自身许可证）。

## 许可证

本项目采用 **[PolyForm Noncommercial License 1.0.0](LICENSE)**：允许出于非商业目的使用、修改与分享；**禁止商业用途**。完整条款见仓库根目录 `LICENSE`。

第三方依赖（Flutter SDK、packages、npm 包等）仍遵循各自许可证，见 `pubspec.yaml` / `riming-web/package.json`。

## 本地数据

- 数据库：应用文档目录下的 `riming.sqlite`（Drift / SQLite）
- 字段含 `id`（UUID）、`updatedAt`、`deletedAt`，便于冲突解决与备份

## 后台计时（Android）

进行中事项会启动前台服务 + 常驻通知。小米等机型可能还需要通知权限、关闭电池优化，以及「后台运行 / 自启动」白名单。

---

<a id="english"></a>

## English

**Riming（日铭）**: phone app = capture; web = analytics.

- **Phone (Flutter)**: one primary button to start/switch activities, local SQLite timeline, liquid-glass UI, optional cloud backup.
- **Web ([`riming-web/`](riming-web/))**: heatmaps, range stats, CSV export — same account as the app.
- **Web URLs**: intended [https://riming.shilongs.top](https://riming.shilongs.top); interim [https://riming-web.wylking.workers.dev](https://riming-web.wylking.workers.dev).
- Build app: `flutter pub get && flutter build apk --release`
- Run web: `cd riming-web && npm install && npm run dev` (copy `.env.local.example`; use your own backend URL/anon key — never commit secrets)
- Deploy web: `cd riming-web && npm run deploy:vinext`
- APK: [Releases v1.0.2](https://github.com/Family2002/riming/releases/tag/v1.0.2)
- License: [PolyForm Noncommercial 1.0.0](LICENSE) — non-commercial use only
- Credits: developed with **Cursor** and **Grok**; glass UI via [liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets)
