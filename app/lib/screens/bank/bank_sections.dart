export 'audit_screen.dart' show BankAuditScreen;
export 'developers_screen.dart' show BankDeveloperScreen, BankDevelopersScreen;
export 'inspections_screen.dart' show BankInspectionsScreen;
export 'objects_screen.dart' show BankObjectScreen, BankObjectsScreen;
export 'portfolio_screen.dart' show BankPortfolioScreen;
export 'reports_screen.dart' show BankReportScreen, BankReportsScreen;
export 'rules_screen.dart' show BankRulesScreen;

import '../../l10n.dart';

String bankQueueSummary(AppCopy copy, int count, String amount, String unit) {
  return '${copy.trancheCount(count)} · $amount $unit';
}
