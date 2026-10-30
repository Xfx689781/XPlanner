import 'dart:io';

import 'package:facet/app/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app_info.dart 的版本号与 pubspec.yaml 一致', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*([\d.]+)\+(\d+)', multiLine: true).firstMatch(pubspec)!;
    expect(appVersion, match.group(1));
    expect(appBuild, int.parse(match.group(2)!));
  });
}
