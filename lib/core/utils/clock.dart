import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 可替换的时钟：测试里注入固定时间。
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());
