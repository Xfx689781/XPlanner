import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 与 MainActivity.kt 里的 MethodChannel 对应。只在 Android 上有效，其他平台返回 null / false。
class SystemSettings {
  const SystemSettings();

  static const _channel = MethodChannel('facet/system_settings');

  bool get _android => !kIsWeb && Platform.isAndroid;

  /// 打开本 App 的「应用信息」页。成功打开返回 true
  Future<bool> openAppDetails() async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('openAppDetails') ?? false;
    } on PlatformException catch (e) {
      debugPrint('打开应用设置失败：$e');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// true = 电池「不受限制」；null = 无法判断
  Future<bool?> isIgnoringBatteryOptimizations() async {
    if (!_android) return null;
    try {
      return await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

extension SystemSettingsAlarm on SystemSettings {
  static const _channel = MethodChannel('facet/system_settings');

  /// 能否使用全屏通知；null = 无法判断（非 Android）
  Future<bool?> canUseFullScreenIntent() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<bool>('canUseFullScreenIntent');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// 闹钟页显示期间允许出现在锁屏上方；离开时传 false
  Future<void> setShowOnLockScreen(bool show) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('setShowOnLockScreen', {'show': show});
    } on PlatformException catch (e) {
      debugPrint('设置锁屏显示失败：$e');
    } on MissingPluginException {
      return;
    }
  }
}

final systemSettingsProvider = Provider<SystemSettings>((ref) => const SystemSettings());
