import 'dart:ffi';
import 'dart:io';

import 'package:spendroo/core/db/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:sqlite3/open.dart';

/// `flutter test` runs on the development machine, which needs its own
/// sqlite3 library. On Windows, set SQLITE3_DLL to a sqlite3.dll if none is on PATH.
void useHostSqlite() {
  // Each test opens a fresh in-memory database on purpose
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final dll = Platform.environment['SQLITE3_DLL'];
  if (Platform.isWindows && dll != null) {
    open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open(dll));
  }
}

AppDatabase memoryDatabase() {
  useHostSqlite();
  return AppDatabase(NativeDatabase.memory());
}
