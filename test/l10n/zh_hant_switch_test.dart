import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/log_repository.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/settings_provider.dart';
import 'package:facet/core/data/settings/settings_repository.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_ids.dart';
import 'package:facet/core/notifications/notification_language.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/core/notifications/reminder_sync_service.dart';
import 'package:facet/core/utils/clock.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:facet/l10n/locale_providers.dart';
import 'package:facet/l10n/supported_locales.dart';
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

  Finder navText(String label) =>
      find.descendant(of: find.byType(GeoNavBar), matching: find.text(label));

  group('切换到繁體中文', () {
    testWidgets('选繁體中文：立即生效（設定 / 一般）、写入 zh-Hant；返回后导航是 今天/任務/日誌；重启后仍是繁体', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(db, clock: clock));
      await tester.pumpAndSettle();
      expect(navText('任务'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('通用'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('繁體中文'));
      await settle(tester);

      expect(find.text('設定'), findsOneWidget); // 设置页标题
      expect(find.text('一般'), findsOneWidget);
      expect(find.text('語言'), findsOneWidget);
      expect(
        await tester.db(() => SettingsRepository(db).raw('language')),
        'zh-Hant',
      );
      final saved = await tester.db(() => SettingsRepository(db).load());
      expect(saved.languageTag, 'zh-Hant');

      await tester.tap(find.bySemanticsLabel('返回').last);
      await tester.pumpAndSettle();
      expect(navText('今天'), findsOneWidget);
      expect(navText('任務'), findsOneWidget);
      expect(navText('日誌'), findsOneWidget);
      expect(navText('任务'), findsNothing);
      expect(find.text('10月30日 週五'), findsOneWidget); // 今天页副标题用 zh_TW 日期数据

      // 重启：用数据库里保存的设置预读；系统语言仍是简体中文
      await tester.disposeApp();
      await tester.pumpWidget(testApp(db, clock: clock, settings: saved));
      await tester.pumpAndSettle();
      expect(navText('任務'), findsOneWidget);
      expect(navText('日誌'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('設定'));
      await tester.pumpAndSettle();
      expect(find.text('設定'), findsOneWidget);
      expect(find.text('一般'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('跟随系统：系统语言在运行中从简体变成 zh_Hant_TW（didChangeLocales），界面切到繁体', (
      tester,
    ) async {
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(testApp(db, clock: clock));
      await tester.pumpAndSettle();
      expect(navText('任务'), findsOneWidget);

      tester.platformDispatcher.localesTestValue = const [
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      ];
      await tester.pumpAndSettle();
      expect(navText('任務'), findsOneWidget);
      expect(
        await tester.db(() => SettingsRepository(db).raw('language')),
        isNull,
      ); // 跟随系统不写库
      await finish(tester);
    });

    testWidgets('繁体 + 12 小时制：日志时间是 上午7:05', (tester) async {
      await tester.db(
        () => LogRepository(db).add('咖啡', now: DateTime(2026, 10, 30, 7, 5)),
      );
      await tester.pumpWidget(
        testApp(
          db,
          clock: clock,
          settings: const AppSettings(languageTag: 'zh-Hant'),
          use24h: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('上午7:05'), findsOneWidget);
      await finish(tester);
    });
  });

  group('通知文字跟随语言', () {
    // 期望值直接写出 ARB 里的文字，防止 ARB 被误改
    const expected = {
      'en': (
        'XPlanner test reminder',
        'If you can see this, reminders are working',
      ),
      'zh-Hans': ('XPlanner 测试提醒', '能看到这条，说明提醒正常'),
      'zh-Hant': ('XPlanner 測試提醒', '看得到這則通知，就表示提醒正常'),
    };
    test('期望表覆盖所有语言', () {
      expect(expected.keys.toSet(), {for (final l in appLanguages) l.tag});
    });

    Future<void> sendTestNotification(
      WidgetTester tester,
      AppLocalizations l10n,
    ) async {
      await tester.tap(find.bySemanticsLabel(l10n.todaySettings));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.settingsSectionReminders).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l10n.settingsTestButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.settingsTestButton));
      await settle(tester);
    }

    for (final lang in appLanguages) {
      testWidgets('${lang.tag}：设置 → 提醒 → 测试通知的标题 / 正文', (tester) async {
        final scheduler = FakeScheduler();
        await tester.pumpWidget(
          testApp(
            db,
            clock: clock,
            settings: AppSettings(languageTag: lang.tag),
            overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
          ),
        );
        await tester.pumpAndSettle();
        final l10n = lookupAppLocalizations(lang.locale);
        await sendTestNotification(tester, l10n);

        final request = scheduler.pending[testNotificationId];
        expect(request, isNotNull);
        expect(request!.title, expected[lang.tag]!.$1);
        expect(request.body, expected[lang.tag]!.$2);
        expect(find.text(l10n.settingsTestScheduledExact), findsOneWidget);
        await finish(tester);
      });
    }

    testWidgets('运行中从简体切到繁体后，测试通知用繁体', (tester) async {
      final scheduler = FakeScheduler();
      await tester.pumpWidget(
        testApp(
          db,
          clock: clock,
          overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('通用'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('繁體中文'));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('返回').last);
      await tester.pumpAndSettle();

      await sendTestNotification(
        tester,
        lookupAppLocalizations(appLanguages.last.locale),
      );
      expect(scheduler.pending[testNotificationId]!.title, 'XPlanner 測試提醒');
      expect(scheduler.pending[testNotificationId]!.body, '看得到這則通知，就表示提醒正常');
      await finish(tester);
    });

    ProviderContainer container(FakeScheduler scheduler) {
      final c = ProviderContainer(
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
      addTearDown(c.dispose);
      return c;
    }

    test('手动切换：简体 → 繁體中文，渠道名变成「任務提醒」，已安排的提醒重排', () async {
      final scheduler = FakeScheduler();
      final c = container(scheduler);
      await TaskRepository(db).create(
        TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)),
        now: clock.value,
      );
      await configureNotificationChannel(c);
      expect(scheduler.channelName, '任务提醒');
      final sub = listenLanguageForNotifications(c);
      addTearDown(sub.close);
      scheduler.log.clear();

      await c.read(settingsProvider.notifier).setLanguageTag('zh-Hant');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(scheduler.channelName, '任務提醒');
      expect(scheduler.log, contains('cancelAllPending'));
      expect(scheduler.taskIds, isNotEmpty);
    });

    // 曾经的 bug：回调里读到的是旧语言，渠道名落后一种语言；现在用回调传入的新语言
    test('连续切换语言：每次切换后渠道名都是新语言的', () async {
      final scheduler = FakeScheduler();
      final c = container(scheduler);
      await configureNotificationChannel(c);
      final sub = listenLanguageForNotifications(c);
      addTearDown(sub.close);

      for (final (tag, name) in [
        ('en', 'Task reminders'),
        ('zh-Hant', '任務提醒'),
        ('zh-Hans', '任务提醒'),
        ('en', 'Task reminders'),
      ]) {
        await c.read(settingsProvider.notifier).setLanguageTag(tag);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(scheduler.channelName, name, reason: '切换到 $tag 后');
      }
    });

    test('跟随系统：系统语言变成 zh_TW 时渠道名变成「任務提醒」', () async {
      final scheduler = FakeScheduler();
      final c = container(scheduler);
      await configureNotificationChannel(c);
      expect(scheduler.channelName, '任务提醒');
      final sub = listenLanguageForNotifications(c);
      addTearDown(sub.close);

      c.read(systemLocalesProvider.notifier).set(const [Locale('zh', 'TW')]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(scheduler.channelName, '任務提醒');
      expect(scheduler.log, contains('configureChannel 任務提醒'));

      // 同为繁体的另一个地区（香港）：语言没变，不重复配置
      scheduler.log.clear();
      c.read(systemLocalesProvider.notifier).set(const [Locale('zh', 'HK')]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(scheduler.log, isEmpty);
    });
  });

  group('语言列表的语言名（autonym）', () {
    for (final ui in appLanguages) {
      testWidgets('界面是 ${ui.tag} 时，每个语言名用它自己的 locale 渲染', (tester) async {
        // 跟随系统：语言名只出现在选项里（"跟随系统"那行的说明是"当前：xx"，文字不同）
        await tester.pumpWidget(
          testApp(db, clock: clock, systemLocales: [ui.locale]),
        );
        await tester.pumpAndSettle();
        final l10n = lookupAppLocalizations(ui.locale);
        await tester.tap(find.bySemanticsLabel(l10n.todaySettings));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.settingsSectionGeneral).first);
        await tester.pumpAndSettle();

        for (final lang in appLanguages) {
          final text = tester.widget<Text>(find.text(lang.autonym));
          expect(
            text.locale,
            lang.locale,
            reason: '${lang.autonym} 在 ${ui.tag} 界面',
          );
        }
        // 选中项之外的文字仍用界面语言
        final follow = find.descendant(
          of: find.byType(GeoOptionList<String?>),
          matching: find.text(l10n.languageFollowSystem),
        );
        expect(tester.widget<Text>(follow).locale, isNull);
        await finish(tester);
      });
    }
  });
}
