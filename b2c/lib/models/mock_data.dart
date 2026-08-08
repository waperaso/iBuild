import 'package:ibuild_core/ibuild_core.dart';

/// Empty offline catalogue for mock mode (`Env.useMockData`).
/// Auth still accepts OTP `123456` via [AuthRepository] — no bundled ЖК.
abstract class MockData {
  static final developers = <Developer>[];
  static final projects = <Project>[];

  static Project projectById(String id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    throw StateError('Project not found: $id');
  }

  static final documentsByDeveloper = <String, List<Document>>{};
  static final photoReportsByProject = <String, List<PhotoReport>>{};
  static final leads = <Lead>[];
}
