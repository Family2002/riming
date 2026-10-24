# 日铭（Riming）

简洁的**每日活动时间线**记录 App：点一下大按钮 → 输入事项 → 再点一下结束并切换下一项。数据保存在本机 SQLite，界面为 Material 3 + 液态玻璃风格。

[English summary](#english) · [下载 APK](https://github.com/Family2002/riming/releases/tag/v1.0.0)

## 功能概览

- 一键开始 / 切换 / 结束事项，时间线自动分段
- 往日记录浏览与事项编辑
- 多套安静日记感主题配色（浅色 / 深色 / 跟随系统）
- Android 前台服务常驻通知，后台计时不断档
- 可选 **Supabase 云同步**（邮箱+密码登录，多设备 last-write-wins）

## 下载

正式预览包见 GitHub **[Releases v1.0.0](https://github.com/Family2002/riming/releases/tag/v1.0.0)**。

> 首发 APK 使用 Flutter 默认 **debug/preview 签名**（未配置独立 release keystore），仅供非商业试用；上架商店前请自行配置正式签名。

## 运行与构建

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

## 使用流程

1. 打开 App，点中间的「开始记录」
2. 输入当前事项（如「起床」）
3. 做完后点「切换事项」，输入下一件事；上一段会自动记上结束时间
4. 需要只结束、不开始下一项时，点「结束当前」
5. 点时间线上的事项可编辑名称与起止时间
6. 右上角可切换主题；日历可查看往日时间线

## 技术栈

Flutter · Material 3 · Riverpod · Drift (SQLite) · Supabase · go_router · Google Fonts · flutter_foreground_task · [liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets)

## 致谢 / Credits

开发过程中由 **Cursor**、**Grok** 作为 AI 协作者参与实现与迭代。

液态玻璃 UI 使用开源库 **[liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets)**（请遵循该仓库自身许可证）。

## 许可证

本项目采用 **[PolyForm Noncommercial License 1.0.0](LICENSE)**：允许出于非商业目的使用、修改与分享；**禁止商业用途**。完整条款见仓库根目录 `LICENSE`。

第三方依赖（Flutter SDK、packages 等）仍遵循各自许可证，见 `pubspec.yaml` / pub.dev。

## 本地数据

- 数据库：应用文档目录下的 `riming.sqlite`（Drift / SQLite）
- 字段含 `id`（UUID）、`updatedAt`、`deletedAt`，用于云同步冲突解决

## 云同步（Supabase）

Auth 选用 **邮箱 + 密码**（Android 上最稳妥，无需配置 magic link 深链）。登录后、从后台回到前台、以及本地写入后会 **先拉后推**；冲突以 `updated_at` 较新为准；每位用户最多一条进行中事项（`end_at` 为空）。**切换登录账号**时会清空本机时间线再拉取，避免串号。

### 本仓库关联项目

| | |
|--|--|
| 名称 / ref | `riming` / `nigkntwnuvgwougpsoux` |
| 区域 | **Tokyo（ap-northeast-1）** |
| API URL | https://nigkntwnuvgwougpsoux.supabase.co |
| Dashboard | https://supabase.com/dashboard/project/nigkntwnuvgwougpsoux |

表结构与 RLS 见迁移：[`supabase/migrations/20261024120000_activities_rls.sql`](supabase/migrations/20261024120000_activities_rls.sql)（已在上述项目应用）。

**自测建议：** 在 Dashboard → [Authentication → Providers → Email](https://supabase.com/dashboard/project/nigkntwnuvgwougpsoux/auth/providers) **关闭 Confirm email**，注册后可立即登录。

### 本地配置（勿提交密钥）

1. 复制 `supabase.env.json.example` → `supabase.env.json`（已 gitignore）
2. 填入 Dashboard → Project Settings → API 的 **anon** / publishable key（勿用 `service_role`）
3. 运行：

```bash
flutter run -d <deviceId> --dart-define-from-file=supabase.env.json
```

其他方式：

```bash
# 方式 A：dart-define
flutter run -d <deviceId> \
  --dart-define=SUPABASE_URL=https://nigkntwnuvgwougpsoux.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY

# 方式 C：.env + 脚本（复制 .env.example → .env）
.\tools\run_with_env.ps1 -Device <deviceId>
```

环境变量：

| 变量 | 含义 |
|------|------|
| `SUPABASE_URL` | 项目 API URL（见上表） |
| `SUPABASE_ANON_KEY` | anon / publishable key（客户端可用；勿用 service_role） |

未配置时 App 仍可离线使用；账号页会提示缺少配置。

App 内入口：首页右上角「账号与同步」。

## 后台计时（Android）

进行中事项会启动前台服务 + 常驻通知。小米等机型可能还需要通知权限、关闭电池优化，以及「后台运行 / 自启动」白名单。

---

<a id="english"></a>

## English

**Riming（日铭）** is a calm daily activity time-log app for Android/Flutter: one primary button to start/switch activities, a local SQLite timeline, themed liquid-glass UI.

- Build: `flutter pub get && flutter build apk --release`
- Cloud sync: Supabase project `riming` in Tokyo — run with `--dart-define-from-file=supabase.env.json` (see Chinese section above)
- APK: [Releases v1.0.0](https://github.com/Family2002/riming/releases/tag/v1.0.0)
- License: [PolyForm Noncommercial 1.0.0](LICENSE) — non-commercial use only
- Credits: developed with **Cursor** and **Grok**; glass UI via [liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets)
