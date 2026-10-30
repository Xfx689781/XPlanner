/// 通知 id 分区：每个任务占 [slotsPerTask] 个连续 id（taskId * slotsPerTask + slot），
/// 1e9 以上留给其他用途。
const int reservedIdBase = 1000000000;

/// 每个任务最多同时挂的提醒数：系统重复只用 slot 0；
/// 跳过今天 / 延后开始时用连续的一次性提醒（见 next_trigger.dart 的窗口大小）
const int slotsPerTask = 8;

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

const _taskPayloadPrefix = 'task:';

String taskPayload(int taskId) => '$_taskPayloadPrefix$taskId';

/// 'task:12' → 12；格式不对返回 null
int? parseTaskPayload(String? payload) {
  if (payload == null || !payload.startsWith(_taskPayloadPrefix)) return null;
  return int.tryParse(payload.substring(_taskPayloadPrefix.length));
}
