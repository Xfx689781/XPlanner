import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _dataLoaded = false;
bool _localSet = false;

/// 加载时区数据库并把 tz.local 设为设备当前时区。
/// 返回时区名；取不到时返回 null：首次失败回退到 UTC（设置页会显示），
/// 之后的失败保留上一次成功的时区，避免一次偶发错误把所有提醒算偏。
Future<String?> initLocalTimezone() async {
  if (!_dataLoaded) {
    tzdata.initializeTimeZones();
    _dataLoaded = true;
  }
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
    _localSet = true;
    return info.identifier;
  } catch (e) {
    debugPrint('获取本地时区失败：$e');
    if (!_localSet) tz.setLocalLocation(tz.UTC);
    return null;
  }
}
