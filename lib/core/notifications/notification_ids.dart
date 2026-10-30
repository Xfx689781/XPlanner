/// 通知 id 分区：每个任务占 [slotsPerTask] 个连续 id（taskId * slotsPerTask + slot），
/// 1e9 以上留给其他用途。
const int reservedIdBase = 1000000000;

/// 每个任务的通知槽位：第 i 个提醒占 [slotsPerReminder] 个（系统重复只用 1 个；
/// 跳过今天 / 延后开始时用连续的一次性提醒，见 next_trigger.dart 的窗口大小），最后一个槽给"稍后提醒"。
/// 5 个提醒 × 3 + 1 = 16
const int slotsPerReminder = 3;
const int slotsPerTask = 16;
const int snoozeSlot = slotsPerTask - 1;

/// 设置页"测试通知"使用的 id
const int testNotificationId = reservedIdBase;

int notificationIdForTask(int taskId, [int slot = 0]) {
  assert(slot >= 0 && slot < slotsPerTask, 'slot 超出范围：$slot');
  final id = taskId * slotsPerTask + slot;
  assert(taskId > 0 && id < reservedIdBase, 'taskId 超出通知 id 范围：$taskId');
  return id;
}

/// 一个任务可能用到的全部通知 id
Iterable<int> notificationIdsForTask(int taskId) =>
    [for (var s = 0; s < slotsPerTask; s++) notificationIdForTask(taskId, s)];

/// 第 [reminderIndex] 个提醒的第 [k] 条
int notificationIdForReminder(int taskId, int reminderIndex, int k) =>
    notificationIdForTask(taskId, reminderIndex * slotsPerReminder + k);

/// 通知 id → 任务 id（保留区段返回 null）
int? taskIdOfNotification(int id) => id >= reservedIdBase ? null : id ~/ slotsPerTask;

const _taskPayloadPrefix = 'task:';
const _alarmPayloadPrefix = 'alarm:';

/// 普通提醒：点击打开任务
String taskPayload(int taskId) => '$_taskPayloadPrefix$taskId';

/// 闹钟提醒：点击 / 全屏拉起闹钟页
String alarmPayload(int taskId) => '$_alarmPayloadPrefix$taskId';

/// 'task:12' 或 'alarm:12' → 12；格式不对返回 null
int? parseTaskPayload(String? payload) {
  if (payload == null) return null;
  for (final prefix in [_taskPayloadPrefix, _alarmPayloadPrefix]) {
    if (payload.startsWith(prefix)) return int.tryParse(payload.substring(prefix.length));
  }
  return null;
}

bool isAlarmPayload(String? payload) => payload != null && payload.startsWith(_alarmPayloadPrefix);
