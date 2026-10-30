import 'package:facet/app/app.dart';
import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/utils/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

class FixedClock implements Clock {
  FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

/// 用内存数据库和固定时钟启动整个 App。
Widget testApp(AppDatabase db, {Clock? clock, List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      if (clock != null) clockProvider.overrideWithValue(clock),
      ...overrides,
    ],
    child: const FacetApp(),
  );
}

extension DbTester on WidgetTester {
  /// 在 widget 测试里直接读写数据库要走真实的异步，否则 drift 的计时器在假时钟下不会推进。
  Future<T> db<T>(Future<T> Function() fn) async => (await runAsync(fn)) as T;

  /// 卸载 App，让 drift 的流查询和计时器正常收尾，避免"Timer is still pending"。
  Future<void> disposeApp() async {
    await pumpWidget(const SizedBox.shrink());
    await pump(const Duration(seconds: 1));
  }
}
