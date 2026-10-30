import 'package:drift/drift.dart';

/// 把"当地钟点"（例如 9:00）存成与时区无关的值。
///
/// 写入时把本地 DateTime 的年月日时分原样放进 UTC，读出时再原样取回成本地时间。
/// 这样换了时区之后，9:00 仍然是当地 9:00，而不是换算成别的钟点。
/// 用于任务的日期时间和提醒时间；创建、完成时间这类"发生的时刻"不用它。
class WallTimeConverter extends TypeConverter<DateTime, DateTime> {
  const WallTimeConverter();

  @override
  DateTime fromSql(DateTime fromDb) {
    final u = fromDb.toUtc();
    return DateTime(u.year, u.month, u.day, u.hour, u.minute, u.second);
  }

  @override
  DateTime toSql(DateTime value) {
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
    );
  }
}
