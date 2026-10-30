/// 通知 id 分区：任务提醒直接用任务 id（< 1e9），1e9 以上留给其他用途。
const int reservedIdBase = 1000000000;

/// 设置页"测试通知"使用的 id
const int testNotificationId = reservedIdBase;

int notificationIdForTask(int taskId) {
  assert(taskId > 0 && taskId < reservedIdBase, 'taskId 超出通知 id 范围：$taskId');
  return taskId;
}

const _taskPayloadPrefix = 'task:';

String taskPayload(int taskId) => '$_taskPayloadPrefix$taskId';

/// 'task:12' → 12；格式不对返回 null
int? parseTaskPayload(String? payload) {
  if (payload == null || !payload.startsWith(_taskPayloadPrefix)) return null;
  return int.tryParse(payload.substring(_taskPayloadPrefix.length));
}
