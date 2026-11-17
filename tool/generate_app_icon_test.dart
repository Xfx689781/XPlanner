// 生成 App 图标：黑底白字的 "XP"（XPlanner 的前两个字母）。
//
// 图形只在这里定义一次，输出到各平台：
// - Android 8+：自适应图标（矢量前景 + 黑色背景），mipmap-anydpi-v26
// - Android 7 及以下：mipmap-*/ic_launcher.png
// - iOS：AppIcon.appiconset 里的全部尺寸（不透明 RGB，App Store 不接受带 alpha 的图标）
// - Windows：windows/runner/resources/app_icon.ico
//
// 改图形后在项目根目录运行：flutter test tool/generate_app_icon_test.dart
// （放在 tool/ 下，平时的 flutter test 不会运行它）
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

// ---- 图形：100 × 100 的坐标系，整个图标铺满 0..100 ----

/// 笔画粗细
const _w = 8.5;

/// X 交叉处压在下面那一笔留出的缝（两侧各一半）
const _slit = 5.0;

/// 一段路径：M / L / A（半径、终点、是否顺时针）/ Z
sealed class _Cmd {
  const _Cmd();
}

class _M extends _Cmd {
  const _M(this.x, this.y);
  final double x, y;
}

class _L extends _Cmd {
  const _L(this.x, this.y);
  final double x, y;
}

class _A extends _Cmd {
  const _A(this.r, this.x, this.y, {required this.clockwise});
  final double r, x, y;
  final bool clockwise;
}

class _Z extends _Cmd {
  const _Z();
}

/// 一个图形元素：白色填充，或黑色描边（在白色笔画之间切出缝）
class _Shape {
  const _Shape(this.cmds, {this.cut = false});
  final List<_Cmd> cmds;
  final bool cut;
}

List<_Cmd> _poly(List<(double, double)> pts) => [
  _M(pts.first.$1, pts.first.$2),
  for (final p in pts.skip(1)) _L(p.$1, p.$2),
  const _Z(),
];

List<_Cmd> _rect(double x, double y, double w, double h) => _poly([(x, y), (x + w, y), (x + w, y + h), (x, y + h)]);

/// 图标：X 的两笔（一笔压一笔，交叉处留缝）；P 比 X 高一截，碗与竖笔断开；下方一条细基线
final List<_Shape> _mark = () {
  const x0 = 18.0, x1 = 50.0, y0 = 30.0, y1 = 70.0;
  final tw = _w * math.sqrt(math.pow(x1 - x0, 2) + math.pow(y1 - y0, 2)) / (y1 - y0);
  final under = _poly([(x1 - tw, y0), (x1, y0), (x0 + tw, y1), (x0, y1)]);
  final over = _poly([(x0, y0), (x0 + tw, y0), (x1, y1), (x1 - tw, y1)]);

  const pTop = 24.0, stemX = 58.0, bowlX = 69.5, cx = 70.0, r = 12.5;
  const bottom = pTop + 2 * r;
  final bowl = <_Cmd>[
    const _M(bowlX, pTop),
    const _L(cx, pTop),
    const _A(r, cx, bottom, clockwise: true),
    const _L(bowlX, bottom),
    const _L(bowlX, bottom - _w),
    const _L(cx, bottom - _w),
    const _A(r - _w, cx, pTop + _w, clockwise: false),
    const _L(bowlX, pTop + _w),
    const _Z(),
  ];
  return [
    _Shape(under),
    _Shape(over, cut: true),
    _Shape(over),
    _Shape(_rect(stemX, pTop, _w, 40)),
    _Shape(bowl),
    _Shape(_rect(x0, 74, cx + r - x0, 1.8)),
  ];
}();

// ---- 绘制 ----

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);

Path _path(List<_Cmd> cmds, double s, Offset o) {
  final p = Path();
  for (final c in cmds) {
    switch (c) {
      case _M(:final x, :final y):
        p.moveTo(o.dx + x * s, o.dy + y * s);
      case _L(:final x, :final y):
        p.lineTo(o.dx + x * s, o.dy + y * s);
      case _A(:final r, :final x, :final y, :final clockwise):
        p.arcToPoint(Offset(o.dx + x * s, o.dy + y * s), radius: Radius.circular(r * s), clockwise: clockwise);
      case _Z():
        p.close();
    }
  }
  return p;
}

/// 在 [size] × [size] 的画布上画图标。[rounded]：圆角方块、四角透明（Windows）
Future<ui.Image> _render(int size, {bool rounded = false}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final s = size / 100;
  final bg = Paint()..color = _black;
  final full = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
  if (rounded) {
    canvas.drawRRect(RRect.fromRectAndRadius(full, Radius.circular(size * 0.22)), bg);
  } else {
    canvas.drawRect(full, bg);
  }
  for (final shape in _mark) {
    final paint = shape.cut
        ? (Paint()
            ..color = _black
            ..style = PaintingStyle.stroke
            ..strokeWidth = _slit * s)
        : (Paint()..color = _white);
    canvas.drawPath(_path(shape.cmds, s, Offset.zero), paint);
  }
  return rec.endRecording().toImage(size, size);
}

Future<Uint8List> _pngRgba(ui.Image img) async =>
    (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();

/// 不带 alpha 通道的 PNG（iOS 图标）
Future<Uint8List> _pngRgb(ui.Image img) async {
  final rgba = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  final w = img.width, h = img.height;
  final raw = BytesBuilder();
  for (var y = 0; y < h; y++) {
    raw.addByte(0); // 每行的过滤方式：无
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      raw.add([rgba[i], rgba[i + 1], rgba[i + 2]]);
    }
  }
  final ihdr = ByteData(13)
    ..setUint32(0, w)
    ..setUint32(4, h)
    ..setUint8(8, 8) // 位深
    ..setUint8(9, 2); // 颜色类型：RGB
  final out = BytesBuilder()..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  _chunk(out, 'IHDR', ihdr.buffer.asUint8List());
  _chunk(out, 'IDAT', Uint8List.fromList(ZLibEncoder().convert(raw.toBytes())));
  _chunk(out, 'IEND', Uint8List(0));
  return out.toBytes();
}

void _chunk(BytesBuilder out, String type, Uint8List data) {
  final typeBytes = type.codeUnits;
  out.add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List());
  out.add(typeBytes);
  out.add(data);
  out.add((ByteData(4)..setUint32(0, _crc32([...typeBytes, ...data]))).buffer.asUint8List());
}

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (var k = 0; k < 8; k++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

/// ICO 容器，每个尺寸存一张 PNG
Uint8List _ico(List<(int, Uint8List)> images) {
  final header = ByteData(6 + 16 * images.length)
    ..setUint16(0, 0, Endian.little)
    ..setUint16(2, 1, Endian.little)
    ..setUint16(4, images.length, Endian.little);
  var offset = header.lengthInBytes;
  for (var i = 0; i < images.length; i++) {
    final (size, png) = images[i];
    final e = 6 + 16 * i;
    header
      ..setUint8(e, size >= 256 ? 0 : size)
      ..setUint8(e + 1, size >= 256 ? 0 : size)
      ..setUint16(e + 4, 1, Endian.little)
      ..setUint16(e + 6, 32, Endian.little)
      ..setUint32(e + 8, png.length, Endian.little)
      ..setUint32(e + 12, offset, Endian.little);
    offset += png.length;
  }
  final out = BytesBuilder()..add(header.buffer.asUint8List());
  for (final (_, png) in images) {
    out.add(png);
  }
  return out.toBytes();
}

// ---- Android 自适应图标（矢量）----

/// 108dp 画布，可见区域约中间 72dp、安全区是直径 66dp 的圆：
/// 把 100 单位的图标缩到 [_adaptiveScale]，以 (54, 54) 为中心
const _adaptiveScale = 0.76;

String _fmt(double v) => v.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

String _pathData(List<_Cmd> cmds) {
  const o = 54 - 50 * _adaptiveScale;
  String p(double x, double y) => '${_fmt(o + x * _adaptiveScale)},${_fmt(o + y * _adaptiveScale)}';
  return [
    for (final c in cmds)
      switch (c) {
        _M(:final x, :final y) => 'M${p(x, y)}',
        _L(:final x, :final y) => 'L${p(x, y)}',
        _A(:final r, :final x, :final y, :final clockwise) =>
          'A${_fmt(r * _adaptiveScale)},${_fmt(r * _adaptiveScale)} 0 0,${clockwise ? 1 : 0} ${p(x, y)}',
        _Z() => 'Z',
      },
  ].join(' ');
}

String _foregroundXml() {
  final paths = [
    for (final s in _mark)
      s.cut
          ? '    <path\n        android:strokeColor="#000000"\n        android:strokeWidth="${_fmt(_slit * _adaptiveScale)}"\n        android:pathData="${_pathData(s.cmds)}" />'
          : '    <path\n        android:fillColor="#FFFFFF"\n        android:pathData="${_pathData(s.cmds)}" />',
  ];
  return '''<?xml version="1.0" encoding="utf-8"?>
<!-- 自适应图标前景：XP。由 tool/generate_app_icon_test.dart 生成，不要手改 -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
${paths.join('\n')}
</vector>
''';
}

const _adaptiveXml = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 由 tool/generate_app_icon_test.dart 生成 -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
''';

const _backgroundColorXml = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 由 tool/generate_app_icon_test.dart 生成 -->
<resources>
    <color name="ic_launcher_background">#000000</color>
</resources>
''';

void main() {
  testWidgets('生成 App 图标', (tester) async {
    await tester.runAsync(() async {
      void write(String path, List<int> bytes) {
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
      }

      // Android
      const res = 'android/app/src/main/res';
      const legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
      for (final MapEntry(key: dpi, value: size) in legacy.entries) {
        write('$res/mipmap-$dpi/ic_launcher.png', await _pngRgba(await _render(size)));
      }
      write('$res/mipmap-anydpi-v26/ic_launcher.xml', utf8.encode(_adaptiveXml));
      write('$res/drawable/ic_launcher_foreground.xml', utf8.encode(_foregroundXml()));
      write('$res/values/ic_launcher_background.xml', utf8.encode(_backgroundColorXml));

      // iOS：按文件名里的尺寸和倍数
      final iconSet = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
      final name = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png$');
      for (final f in iconSet.listSync().whereType<File>()) {
        final m = name.firstMatch(f.path.replaceAll(r'\', '/'));
        if (m == null) continue;
        final px = (double.parse(m.group(1)!) * int.parse(m.group(2)!)).round();
        write(f.path, await _pngRgb(await _render(px)));
      }

      // Windows
      final ico = <(int, Uint8List)>[
        for (final size in [16, 24, 32, 48, 64, 256]) (size, await _pngRgba(await _render(size, rounded: true))),
      ];
      write('windows/runner/resources/app_icon.ico', _ico(ico));
    });
  });
}
