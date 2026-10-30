# 翻译备注

v1.0 支持 English（模板、兜底）、简体中文、繁體中文。以下是需要请母语者检查的用词。

## 全局用词约定

| 概念 | English | 简体中文 | 繁體中文（台湾） |
|---|---|---|---|
| Settings | Settings | 设置 | 設定 |
| Task | Task | 任务 | 任務 |
| Quick log | Log | 日志 | 日誌 |
| Log entry | Entry | 记录 | 紀錄 |
| Reminder | Reminder | 提醒 | 提醒 |
| Save | Save | 保存 | 儲存 |
| Add / New | Add / New | 添加 / 新建 | 新增 |
| Priority | Priority | 优先级 | 優先順序 |
| Week | Week | 周 | 週 |
| Turn on (a permission) | Turn on | 开启 | 開啟 |
| Follow system | Follow system | 跟随系统 | 跟隨系統 |
| App (in system settings) | Apps | 应用 | 應用程式 |
| Data | Data | 数据 | 資料 |
| Lock screen | Lock screen | 锁定屏幕 | 鎖定畫面 |

## 不太确定、需要检查的地方

### 繁體中文
- **三星 One UI 菜单名**（`settingsSamsungStep1`–`Step3`）：按台湾版 One UI 写成「背景使用限制」「休眠應用程式」「深度休眠應用程式」「永不休眠的應用程式」「鎖定畫面」。不同 One UI 版本和香港版可能叫法不同，需要对照真机核对。
- **「鬧鐘與提醒」**（`settingsExactAlarms`）：Android 繁中系统里这个特殊权限的名称，也可能是「鬧鐘和提醒」，需要在真机的「特殊應用程式存取權」里确认。
- **「日誌」 vs 「紀錄」**：导航和页面标题用「日誌」，单条记录用「紀錄」。如果觉得「日誌」太正式，可以改成「隨手記」。
- **「優先順序」**：台湾常用，也有人用「優先級」或「重要性」。
- **「依語言習慣」**（`weekStartLocale`）：简体是「跟随语言」，繁体改成更口语的说法，需确认是否自然。
- **香港用户**：系统是 zh_HK 时也会使用这份台湾用语的繁体。如果以后有较多香港用户，可以增加 `app_zh_HK.arb`（用词如「設定」相同，但「資料 / 數據」「螢幕 / 熒幕」等有差异）。

### English
- **"Log"**（导航）：指快速记录。也可以考虑 "Notes" 或 "Journal"，但 Journal 将来留给日记功能。
- **Samsung menu names**（`settingsSamsungStep1`–`Step3`）：按英文版 One UI 写成 "Background usage limits"、"Sleeping apps"、"Deep sleeping apps"、"Never sleeping apps"，需要对照真机。
- **"Alarms & reminders"**：Android 英文系统里这个特殊权限的官方名称，应该准确。

### 简体中文
- **三星菜单名**：按国行 One UI 写成「后台使用限制」「休眠应用」「深度休眠应用」「永不休眠的应用」，不同版本可能略有差异。

## 1.1 计划增加的语言
日本語、한국어、Español、Français、Deutsch、Português (Brasil)。新增方法见 CLAUDE.md「多语言」。
