import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _dataLoaded = false;

/// 加载时区数据库并把 tz.local 设为设备当前时区。
/// 返回时区名；取不到时回退到 UTC 并返回 null（提醒时间会偏差，设置页会提示）。
Future<String?> initLocalTimezone() async {
  if (!_dataLoaded) {
    tzdata.initializeTimeZones();
    _dataLoaded = true;
  }
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
    return info.identifier;
  } catch (e) {
    debugPrint('获取本地时区失败，回退到 UTC：$e');
    tz.setLocalLocation(tz.UTC);
    return null;
  }
}
