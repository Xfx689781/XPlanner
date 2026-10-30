import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/core/notifications/reminder_status.dart';
import 'package:facet/core/notifications/reminder_sync_service.dart';
import 'package:facet/core/utils/clock.dart';
import 'package:facet/core/utils/timezone_setup.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

const _tzChannel = MethodChannel('flutter_timezone');

/// 让 flutter_timezone 的平台通道返回 [name]；null 表示通道不存在（MissingPluginException）。
void _mockDeviceTimezone(String? name) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    _tzChannel,
    name == null ? null : (call) async => call.method == 'getLocalTimezone' ? name : null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeScheduler scheduler;
  late ProviderContainer container;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));

  setUpAll(() async {
    // 模拟 main() 里启动时成功拿到一次时区：之后的失败应保留这个时区
    _mockDeviceTimezone('America/New_York');
    expect(await initLocalTimezone(), 'America/New_York');
  });

  ProviderContainer make(FakeScheduler s) {
    return ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock),
      reminderSchedulerProvider.overrideWithValue(s),
      reminderSyncProvider.overrideWith((ref) => ReminderSyncService(
        scheduler: s,
        repository: ref.watch(taskRepositoryProvider),
        clock: clock,
      )),
    ]);
  }

  setUp(() {
    db = openTestDb();
    scheduler = FakeScheduler();
    container = make(scheduler);
    _mockDeviceTimezone('America/New_York');
    tz.setLocalLocation(tz.getLocation('America/New_York'));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    _mockDeviceTimezone(null);
  });

  ReminderMonitor monitor() => container.read(reminderMonitorProvider);

  test('平台不支持：什么都不做，也不改 tz.local', () async {
    final unsupported = FakeScheduler(supported: false);
    final c = make(unsupported);
    addTearDown(c.dispose);
    _mockDeviceTimezone('Asia/Shanghai');

    await c.read(reminderMonitorProvider).onResume();
    await c.read(reminderMonitorProvider).onResume();

    expect(unsupported.log, isEmpty);
    expect(tz.local.name, 'America/New_York');
  });

  test('首次 onResume 只记录基线，时区和权限都没变时不重建', () async {
    await container.read(taskRepositoryProvider).create(
      TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)),
      now: clock.value,
    );
    await monitor().onResume();
    await monitor().onResume();
    expect(scheduler.log, isNot(contains('cancelAll')));
  });

  test('首次 onResume 时精确权限是"无"：不算变化，不重建', () async {
    scheduler.exactAllowed = false;
    await monitor().onResume();
    expect(scheduler.log, isEmpty);
  });

  test('精确闹钟权限从无到有：重建所有提醒', () async {
    final t = await container.read(taskRepositoryProvider).create(
      TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)),
      now: clock.value,
    );
    scheduler.exactAllowed = false;
    await monitor().onResume();
    expect(scheduler.log, isEmpty);

    scheduler.exactAllowed = true;
    await monitor().onResume();
    expect(scheduler.log.first, 'cancelAll');
    expect(scheduler.pending.keys, [t.id]);

    // 再回到前台、权限没变：不再重建
    scheduler.log.clear();
    await monitor().onResume();
    expect(scheduler.log, isEmpty);
  });

  test('精确闹钟权限被收回：也重建（降级为不精确调度）', () async {
    await monitor().onResume();
    scheduler.exactAllowed = false;
    await monitor().onResume();
    expect(scheduler.log, ['cancelAll']);
  });

  test('设备时区变化：更新 tz.local 并重建', () async {
    await monitor().onResume();
    expect(scheduler.log, isEmpty);

    _mockDeviceTimezone('Asia/Shanghai');
    await monitor().onResume();
    expect(tz.local.name, 'Asia/Shanghai');
    expect(scheduler.log, ['cancelAll']);
  });

  test('首次 onResume 就发现时区与启动时不同：重建', () async {
    _mockDeviceTimezone('Europe/London');
    await monitor().onResume();
    expect(tz.local.name, 'Europe/London');
    expect(scheduler.log, ['cancelAll']);
  });

  test('获取时区失败（平台通道不存在）：保留已设置的 tz.local，不重建', () async {
    await monitor().onResume();
    _mockDeviceTimezone(null);
    await monitor().onResume();
    expect(tz.local.name, 'America/New_York');
    expect(scheduler.log, isEmpty);
  });

  test('获取时区失败后恢复且时区确实变了：重建', () async {
    await monitor().onResume();
    _mockDeviceTimezone(null);
    await monitor().onResume();
    _mockDeviceTimezone('Asia/Tokyo');
    await monitor().onResume();
    expect(tz.local.name, 'Asia/Tokyo');
    expect(scheduler.log, ['cancelAll']);
  });

  test('canScheduleExact 为 null（iOS 等不需要这个权限）：永远不因权限重建', () async {
    final s = _NullExactScheduler();
    final c = make(s);
    addTearDown(c.dispose);
    await c.read(reminderMonitorProvider).onResume();
    await c.read(reminderMonitorProvider).onResume();
    expect(s.log, isEmpty);
  });
}

class _NullExactScheduler extends FakeScheduler {
  @override
  Future<bool?> canScheduleExact() async => null;
}
