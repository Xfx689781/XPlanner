import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// 所有测试共用：先加载 intl 的日期数据（与 main 里一致），按语言格式化日期才不会抛 LocaleDataException。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  await testMain();
}
