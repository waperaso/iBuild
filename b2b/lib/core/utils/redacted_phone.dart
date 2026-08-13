import 'package:ibuild_core/ibuild_core.dart';

import '../../l10n/gen/app_localizations.dart';

/// Real phone numbers that must never render in the B2B UI, no matter who
/// is signed in or where the number appears — e.g. the seeded dev admin's
/// personal number created by `_seedDefaultAdmins`
/// (`server/lib/src/store.dart`, non-production only). Keep in sync with
/// `SYSTEM_ADMIN_PHONES` dev defaults on the server.
const _alwaysHiddenPhones = {'+998903306416'};

/// True while a demo session is active, or when [phone] is one of the
/// numbers that must never be rendered regardless of session type.
bool isPhoneRedacted(String? phone) =>
    DemoSession.isActive || _alwaysHiddenPhones.contains(phone?.trim());

/// Returns [phone] as-is unless it must be redacted: any phone while a demo
/// session is active, or one of [_alwaysHiddenPhones] regardless of session
/// type (top bar, sidebar, users list, audit log, dialogs — everywhere).
String displayPhone(AppLocalizations l10n, String? phone) {
  final trimmed = phone?.trim() ?? '';
  if (trimmed.isEmpty) return '';
  if (isPhoneRedacted(trimmed)) return l10n.phoneHidden;
  return trimmed;
}
