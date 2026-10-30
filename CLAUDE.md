# 项目：Facet（暂定名）— 几何风格的 计划 / 日记 / 回顾 App

产品需求见 SPEC.md。开始任何功能前先读 SPEC.md 对应章节。

## 技术栈
- Flutter（Dart），一套代码出 Windows、Android、iOS
- 开发顺序：先 Windows（开发时直接在电脑上运行）→ Android → 最后 iOS
- 状态管理：Riverpod（flutter_riverpod）
- 本地数据库：drift（SQLite）
- 提醒：flutter_local_notifications
- 生物识别锁：local_auth（Windows Hello / 指纹 / Face ID）
- 日期格式：intl
- 只允许使用以上依赖，加上 path_provider、path 这类官方或基础包。需要其他包时先说明理由并等我确认
- 某个平台不支持的功能（例如部分通知能力），要做平台判断并优雅降级，不能崩溃

## 目录结构
```
lib/
├── main.dart
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
dart run build_runner build -d        # drift 改表后重新生成代码
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

## 工作规则
- 一次只做一个里程碑里的一个任务，完成后简要汇报改了什么，等我确认再继续
- 修改数据库表结构前先说明影响；发布后任何表结构改动都必须写 drift 迁移并升级 schemaVersion
- 日期计算统一用本地时间，时区、夏令时、跨月、跨年情况必须有测试
- 不要修改应用签名、包名（applicationId / Bundle ID）配置，这些我自己改
- 用户数据默认只存本地，不发送到任何网络地址
- 每完成一个任务，用简短中文说明提交一次 git
