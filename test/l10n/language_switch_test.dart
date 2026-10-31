import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/log_repository.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/settings_provider.dart';
import 'package:facet/core/data/settings/settings_repository.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_language.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/core/notifications/reminder_sync_service.dart';
import 'package:facet/core/utils/clock.dart';
import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:facet/l10n/locale_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/fake_scheduler.dart';
import '../helpers/test_app.dart';
import '../helpers/test_db.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));
  setUp(() => db = openTestDb());

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('跟随系统：系统是英文时界面是英文，系统是中文时界面是中文', (tester) async {
    await tester.pumpWidget(
      testApp(db, clock: clock, systemLocales: const [Locale('en', 'US')]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Tasks'), findsWidgets);
    await tester.disposeApp();

    await tester.pumpWidget(
      testApp(db, clock: clock, systemLocales: const [Locale('zh', 'CN')]),
    );
    await tester.pumpAndSettle();
    expect(find.text('今天'), findsWidgets);
    await finish(tester);
  });

  testWidgets('不支持的系统语言用 English 兜底', (tester) async {
    await tester.pumpWidget(
      testApp(db, clock: clock, systemLocales: const [Locale('it', 'IT')]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsWidgets);
    await finish(tester);
  });

  testWidgets('设置里选 English：立即生效、写入数据库；重启后仍是 English；选回跟随系统后删除该行', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(db, clock: clock));
    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('通用'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await settle(tester);
    // 不用重启，界面立刻是英文
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    final saved = await tester.db(() => SettingsRepository(db).load());
    expect(saved.languageTag, 'en');

    // 重启（用保存的设置预读）
    await tester.disposeApp();
    await tester.pumpWidget(testApp(db, clock: clock, settings: saved));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsWidgets);

    // 选回跟随系统（测试里系统是中文）
    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Follow system').last);
    await settle(tester);
    expect(find.text('语言'), findsOneWidget);
    expect(
      await tester.db(() => SettingsRepository(db).raw('language')),
      isNull,
    );
    await finish(tester);
  });

  testWidgets('英文界面：日期、优先级读屏、复数、分组标题都用英文', (tester) async {
    await tester.db(() async {
      final repo = TaskRepository(db);
      await repo.create(
        TaskDraft(
          title: 'Pay rent',
          dueAt: DateTime(2026, 10, 28),
          priority: Priority.high,
        ),
        now: clock.value,
      );
      await repo.create(
        TaskDraft(title: 'Call mom', dueAt: DateTime(2026, 10, 30)),
        now: clock.value,
      );
    });
    await tester.pumpWidget(
      testApp(
        db,
        clock: clock,
        settings: const AppSettings(languageTag: 'en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fri, Oct 30'), findsOneWidget); // 今天页副标题
    expect(find.text('Overdue'), findsOneWidget);
    expect(
      find.bySemanticsLabel('0 of 1 task done today'),
      findsOneWidget,
    ); // 复数 =1
    expect(
      find.bySemanticsLabel(RegExp(r'^Pay rent, high priority, overdue$')),
      findsOneWidget,
    );
    await finish(tester);
  });

  test('复数：英文 1 / 多个，中文统一', () {
    final en = lookupAppLocalizationsFor('en');
    final zh = lookupAppLocalizationsFor('zh');
    expect(en.todayProgressSemantics(0, 1), '0 of 1 task done today');
    expect(en.todayProgressSemantics(2, 3), '2 of 3 tasks done today');
    expect(en.durationMinutes(1), '1 minute');
    expect(en.durationMinutes(15), '15 minutes');
    expect(zh.durationMinutes(5), '5 分钟');
    expect(zh.todayProgressSemantics(1, 1), '今天完成 1 / 1');
  });

  test('切换语言：通知渠道名跟着变，已安排的提醒按新语言重排', () async {
    final scheduler = FakeScheduler();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        reminderSyncProvider.overrideWith(
          (ref) => ReminderSyncService(
            scheduler: scheduler,
            repository: ref.watch(taskRepositoryProvider),
            clock: clock,
            location: () => tz.UTC,
          ),
        ),
        systemLocalesProvider.overrideWith(ZhSystemLocales.new),
      ],
    );
    addTearDown(container.dispose);
    await TaskRepository(db).create(
      TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)),
      now: clock.value,
    );

    await configureNotificationChannel(container);
    expect(scheduler.channelName, '任务提醒');
    final sub = listenLanguageForNotifications(container);
    addTearDown(sub.close);
    scheduler.log.clear();

    await container.read(settingsProvider.notifier).setLanguageTag('en');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(scheduler.channelName, 'Task reminders');
    expect(scheduler.log, contains('cancelAllPending'));
    expect(scheduler.taskIds, isNotEmpty);

    // 同一语言再设一次不重排
    scheduler.log.clear();
    await container.read(settingsProvider.notifier).setLanguageTag('en');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(scheduler.log, isEmpty);
  });

  testWidgets('24 小时制跟随系统设置：12 小时制时英文显示 AM/PM', (tester) async {
    await tester.db(
      () => LogRepository(db).add('coffee', now: DateTime(2026, 10, 30, 7, 5)),
    );
    await tester.pumpWidget(
      testApp(
        db,
        clock: clock,
        settings: const AppSettings(languageTag: 'en'),
        use24h: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('7:05'), findsOneWidget);
    expect(find.textContaining('AM'), findsOneWidget);
    await finish(tester);
  });
}

AppLocalizations lookupAppLocalizationsFor(String code) =>
    lookupAppLocalizations(Locale(code));
