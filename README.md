# 日铭（Riming）

简洁的**每日活动时间线**记录 App：点一下大按钮 → 输入事项 → 再点一下结束并切换下一项。数据保存在本机 SQLite，界面为 Material 3 + 液态玻璃风格。本仓库同时包含可选的网页分析端（`riming-web/`）。

[English summary](#english) · [下载 APK](https://github.com/Family2002/riming/releases/tag/v1.0.2)

## 功能概览

- 一键开始 / 切换 / 结束事项，时间线自动分段
- 往日记录浏览、事项编辑与轻量当日摘要
- 多套安静日记感主题配色（浅色 / 深色 / 跟随系统）
- Android 前台服务常驻通知，后台计时不断档
- 可选**云同步 / 账号备份**（邮箱登录后多设备同步）
- 可选**网页分析**（热力图、区间统计、CSV 导出；与 App 同一账号）

## 下载

正式预览包见 GitHub **[Releases v1.0.2](https://github.com/Family2002/riming/releases/tag/v1.0.2)**。

> 首发 APK 使用 Flutter 默认 **debug/preview 签名**（未配置独立 release keystore），仅供非商业试用；上架商店前请自行配置正式签名。

## 仓库结构

| 路径 | 说明 |
|------|------|
| `lib/`、`android/` … | Flutter 手机 App |
| [`riming-web/`](riming-web/) | 网页分析（Next.js / vinext，可部署 Cloudflare Workers） |

## 运行与构建

### Flutter App

```bash
flutter pub get
flutter devices
flutter run -d <deviceId>

# Release APK
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

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
cp .env.local.example .env.local   # 填入你自己的 Supabase Project URL 与 anon key
npm run dev                        # http://localhost:3000
```

可选 Cloudflare Workers 部署（vinext）：在 `riming-web/` 配置好环境变量后执行 `npm run deploy:vinext`。不要把 `.env.local` 或密钥提交进仓库。

## 使用流程

1. 打开 App，点中间的「开始记录」
2. 输入当前事项（如「起床」）
3. 做完后点「切换事项」，输入下一件事；上一段会自动记上结束时间
4. 需要只结束、不开始下一项时，点「结束当前」
5. 点时间线上的事项可编辑名称与起止时间
6. 右上角可切换主题、账号同步；日历可查看往日时间线

## 技术栈

Flutter · Material 3 · Riverpod · Drift (SQLite) · go_router · Google Fonts · flutter_foreground_task · [liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets)

## 致谢 / Credits

开发过程中由 **Cursor**、**Grok** 作为 AI 协作者参与实现与迭代。

液态玻璃 UI 使用开源库 **[liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets)**（请遵循该仓库自身许可证）。

## 许可证

本项目采用 **[PolyForm Noncommercial License 1.0.0](LICENSE)**：允许出于非商业目的使用、修改与分享；**禁止商业用途**。完整条款见仓库根目录 `LICENSE`。

第三方依赖（Flutter SDK、packages 等）仍遵循各自许可证，见 `pubspec.yaml` / pub.dev。

## 本地数据

- 数据库：应用文档目录下的 `riming.sqlite`（Drift / SQLite）
- 字段含 `id`（UUID）、`updatedAt`、`deletedAt`，便于冲突解决与备份

## 后台计时（Android）

进行中事项会启动前台服务 + 常驻通知。小米等机型可能还需要通知权限、关闭电池优化，以及「后台运行 / 自启动」白名单。

---

<a id="english"></a>

## English

**Riming（日铭）** is a calm daily activity time-log app for Android/Flutter: one primary button to start/switch activities, a local SQLite timeline, themed liquid-glass UI, with optional cloud backup via account login. Optional web analytics live in [`riming-web/`](riming-web/).

- Build: `flutter pub get && flutter build apk --release`
- Web: `cd riming-web && npm install && npm run dev` (see that folder’s README; set your own Supabase URL/anon key locally)
- APK: [Releases v1.0.2](https://github.com/Family2002/riming/releases/tag/v1.0.2)
- License: [PolyForm Noncommercial 1.0.0](LICENSE) — non-commercial use only
- Credits: developed with **Cursor** and **Grok**; glass UI via [liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets)
