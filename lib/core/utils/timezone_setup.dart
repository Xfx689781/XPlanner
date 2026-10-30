import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _dataLoaded = false;
bool _localSet = false;
bool _fallback = false;

/// true = 没取到设备时区名，tz.local 是按当前 UTC 偏移推测的（设置页会提示）
bool get timezoneIsFallback => _fallback;

/// 加载时区数据库并把 tz.local 设为设备当前时区。
/// 返回时区名；取不到时返回 null：首次失败按设备当前的 UTC 偏移选一个时区，
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
    _fallback = false;
    return info.identifier;
  } catch (e) {
    debugPrint('获取本地时区失败：$e');
    if (!_localSet) {
      tz.setLocalLocation(_locationMatchingDeviceOffset());
      _fallback = true;
    }
    return null;
  }
}

/// 找一个当前偏移与设备一致的时区；没有则用 UTC。
/// 只保证"现在"的钟点正确，夏令时切换可能差一小时，所以要标记为推测。
tz.Location _locationMatchingDeviceOffset() {
  final now = DateTime.now();
  final offset = now.timeZoneOffset;
  tz.Location? byOffset;
  for (final loc in tz.timeZoneDatabase.locations.values) {
    final t = tz.TZDateTime.from(now, loc);
    if (t.timeZoneOffset != offset) continue;
    if (t.timeZoneName == now.timeZoneName) return loc;
    byOffset ??= loc;
  }
  return byOffset ?? tz.UTC;
}
