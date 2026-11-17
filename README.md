<p align="center">
  <img src="ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" width="128" alt="XPlanner 图标">
</p>

<h1 align="center">XPlanner</h1>

<p align="center">几何风格的计划 / 日志 App：用方块、圆和线，把每一天变成看得见的形状。</p>

<p align="center">
  <a href="https://github.com/Xfx689781/XPlanner/releases/latest"><b>⬇ 下载最新版本（Android APK）</b></a>
</p>

---

## 下载与安装（Android）

1. 用手机浏览器打开 **[Releases 最新版本](https://github.com/Xfx689781/XPlanner/releases/latest)**
2. 在 **Assets** 里下载适合你手机的 APK：

   | 文件 | 适用 |
   | --- | --- |
   | `app-arm64-v8a-release.apk` | **绝大多数手机选这个**（近几年的三星、小米、华为、Pixel 等） |
   | `app-armeabi-v7a-release.apk` | 很旧的 32 位手机 |
   | `app-x86_64-release.apk` | 电脑上的 Android 模拟器 |

3. 打开下载好的文件，第一次会提示「允许此来源安装应用」，允许后返回点 **安装**
4. 如果 Play 保护机制提示风险，点 **仍然安装**（因为不是从 Play 商店下载的，属于正常提示）

- 系统要求：Android 7.0 及以上
- 升级：直接下载新版本覆盖安装，数据会保留

### 安装后建议（让提醒准时响）

- 第一次打开时允许 **通知** 权限
- 在 App 的 **设置 → 提醒** 里按提示开启「闹钟和提醒」（精确闹钟）和全屏提醒
- 三星等手机：系统设置 → 应用程序 → XPlanner → 电池 → 选 **不受限制**，否则省电模式可能拦截提醒

## 功能

- **今天**：顶部一个大圆，按今天任务的完成比例逐渐填满；下面是今天的任务和日志
- **任务**：标题、备注、日期时间、三档优先级。方块空心 = 未完成，实心 = 完成，描边越粗优先级越高
- **提醒**：到点弹出通知，支持不重复 / 每天 / 每周，一个任务可设多个提前提醒；可以设成闹钟式全屏提醒，在通知上直接点「完成」或「稍后 10 分钟」；手机重启后依然有效
- **快速日志**：一句话 + 自动时间戳，按天分组
- 浅色 / 深色主题，简体中文 / 繁體中文 / English

## 隐私

所有数据只保存在你的手机本地，不上传、不联网，没有账号、广告或统计。

## 从源码构建

需要 [Flutter](https://docs.flutter.dev/get-started/install)（3.47 及以上）。

```bash
flutter pub get
flutter run -d windows                    # 在 Windows 上运行
flutter build apk --release --split-per-abi
```

release 构建需要你自己的签名文件：按 `android/app/build.gradle.kts` 里的说明创建 `android/key.properties`（不要提交到 git）。

## 平台

| 平台 | 状态 |
| --- | --- |
| Android | ✅ 可用 |
| Windows | 可以从源码运行，安装包暂未发布 |
| iOS | 计划中 |
