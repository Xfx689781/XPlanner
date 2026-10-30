# 项目：Facet（暂定名）— 几何风格的 计划 / 日记 / 回顾 App

产品需求见 SPEC.md。开始任何功能前先读 SPEC.md 对应章节。

## 技术栈
- Flutter（Dart），一套代码出 Windows、Android、iOS
- 开发顺序：先 Windows（开发时直接在电脑上运行）→ Android → 最后 iOS
- 状态管理：Riverpod（flutter_riverpod）
- 本地数据库：drift（SQLite）
- 提醒：flutter_local_notifications
- 生物识别锁：local_auth（Windows Hello / 指纹 / Face ID）
- 日期格式与多语言：intl、flutter_localizations（SDK 自带）
- 定时通知时区：timezone、flutter_timezone
- 只允许使用以上依赖，加上 path_provider、path 这类官方或基础包。需要其他包时先说明理由并等我确认
- 某个平台不支持的功能（例如部分通知能力），要做平台判断并优雅降级，不能崩溃

## 目录结构
```
lib/
├── main.dart
├── l10n/             # 多语言：app_*.arb、supported_locales.dart、generated/（gen-l10n 生成）
├── app/              # App 入口、路由、主题
├── design_system/    # 颜色、间距、线宽、字号、几何组件（唯一的视觉来源）
├── core/
│   ├── data/         # drift 数据库、表定义、迁移、仓库类
│   ├── notifications/# 通知调度
│   └── utils/        # 日期、时区工具
└── features/
    ├── today/        # 每日页
    ├── plan/         # 计划 / 待办
    ├── journal/      # 每日日记
    ├── log/          # 快速记录
    ├── review/       # 周 / 月 / 年回顾
    └── settings/
test/                 # 单元测试和 Widget 测试，目录结构与 lib/ 对应
```

## 常用命令
```
flutter pub get                       # 安装依赖
dart run build_runner build           # drift 改表后重新生成代码
dart run drift_dev make-migrations    # 改表前后各跑一次：保存表结构快照、生成迁移测试
flutter gen-l10n                      # 改 ARB 后重新生成（flutter run/test 也会自动生成）
flutter analyze                       # 静态检查，必须 0 个 error
flutter test                          # 跑测试
flutter run -d windows                # 在 Windows 上运行
flutter build windows                 # 打包 Windows 版
flutter build apk --release           # 打包 Android APK
```
- 每次改完代码先跑 flutter analyze，有 error 自己修到通过
- 每个功能完成后必须跑 flutter test

## 设计系统（必须遵守）
- 颜色、间距、圆角、线宽、字号只能从 lib/design_system/ 中取，禁止在 Widget 里写死数值
- 视觉语言以几何形状为核心，具体规则见 SPEC.md「设计语言」
- 几何图形用 CustomPainter 或基础 Widget（Container + BoxDecoration）绘制
- 新的可复用视觉元素先加进 design_system/，再在功能里使用
- 浅色和深色主题都要支持
- 布局要同时适配手机竖屏和 Windows 宽窗口（宽屏可以用左侧导航栏 + 内容区）

## 设置
- 所有设置存在 drift 的 SettingEntries 键值表，统一通过 settingsProvider（AppSettings）读写
- 新增设置项：SettingKeys 加一个键 + AppSettings 加字段和 setter + 对应分组（lib/features/settings/sections/）里加一个 ChoiceSetting 等；不需要迁移

## 多语言
- 界面文字（含 Semantics 读屏标签、通知文字、SnackBar）只能来自 lib/l10n/app_*.arb，模板是 app_en.arb；禁止在代码里写死界面文字
- design_system 组件不依赖 l10n，文字（含读屏标签）由调用方传入
- 新增文字：先加进 app_en.arb（必须带 @key 描述），再加进所有其他 ARB；数量用 ICU plural，带变量用占位符，禁止拼接字符串
- 日期时间只能用 AppDateFormat（lib/core/utils/format.dart，intl 按当前语言格式化）；12 / 24 小时制跟随手机系统设置
- 一周第一天只用 effectiveFirstWeekday / MaterialLocalizations.firstDayOfWeekIndex，不写死
- flutter gen-l10n 输出到 lib/l10n/generated/（提交 git）；生成后 l10n_untranslated.json 必须是 {}
- 新增一种语言（只需两处改动）：
  1. 复制 lib/l10n/app_en.arb 为 lib/l10n/app_<语言>.arb（文字 / 地区变体用下划线，如 app_zh_Hant.arb、app_pt_PT.arb，且必须已有该语言的基础文件 app_zh.arb / app_pt.arb），改 "@@locale"，翻译全部值（不需要 @key 描述）
  2. 在 lib/l10n/supported_locales.dart 的 appLanguages 里加一行 AppLanguage(tag, locale, autonym 自称名, intlLocale)；intl 日期数据名与 locale 不同时 intlLocale 要单独填（例如 zh-Hant → zh_TW）
  然后：flutter gen-l10n → 检查 l10n_untranslated.json 为 {} → flutter analyze → flutter test（语言列表一致性测试和 test/l10n/overflow_test.dart 溢出测试会自动覆盖新语言）
  先确认该语言在 Flutter 的 kMaterialSupportedLanguages 里，否则日期 / 时间选择器不会翻译；做 iOS 时在 ios/Runner/Info.plist 的 CFBundleLocalizations 加上该语言
- 不太确定的译法记在 lib/l10n/TRANSLATION_NOTES.md，方便请母语者检查

## 工作规则
- 一次只做一个里程碑里的一个任务，完成后简要汇报改了什么，等我确认再继续
- 修改数据库表结构前先说明影响；发布后任何表结构改动都必须写 drift 迁移并升级 schemaVersion
- 日期计算统一用本地时间，时区、夏令时、跨月、跨年情况必须有测试
- 不要修改应用签名、包名（applicationId / Bundle ID）配置，这些我自己改
- 用户数据默认只存本地，不发送到任何网络地址
- 每完成一个任务，用简短中文说明提交一次 git
