/// 存储为序号：只能在末尾追加，不能调整顺序。
enum Priority { low, medium, high }

/// 提醒方式：普通通知 / 闹钟（持续响铃）。存储为序号：只能在末尾追加。
enum ReminderKind { notification, alarm }

/// 提醒重复规则。存储为序号：只能在末尾追加。
enum RepeatRule { none, daily, weekly }
