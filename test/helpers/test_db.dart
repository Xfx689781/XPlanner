import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:facet/core/data/app_database.dart';

AppDatabase openTestDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
