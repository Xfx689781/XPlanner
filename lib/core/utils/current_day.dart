import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clock.dart';
import 'date_utils.dart';

/// 当前是哪一天（00:00）。到本地零点自动切换；App 回到前台时由外壳调用 [refresh]。
class CurrentDay extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    return _computeAndSchedule();
  }

  void refresh() {
    final day = _computeAndSchedule();
    if (day != state) state = day;
  }

  DateTime _computeAndSchedule() {
    final now = ref.read(clockProvider).now();
    _timer?.cancel();
    // 多等一秒，避免计时器略早触发时还停在前一天
    _timer = Timer(nextDay(now).difference(now) + const Duration(seconds: 1), refresh);
    return startOfDay(now);
  }
}

final currentDayProvider = NotifierProvider<CurrentDay, DateTime>(CurrentDay.new);
