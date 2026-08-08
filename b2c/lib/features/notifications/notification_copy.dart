import '../../core/network/ws_client.dart';
import '../../l10n/gen/app_localizations.dart';
import 'models/app_notification.dart';

/// Localized title/body for a buyer-facing notification.
({String title, String body}) buyerNotificationCopy(
  AppLocalizations l10n,
  AppNotification notification,
) {
  return switch (notification.type) {
    WsEventType.leadStatusChanged => (
      title: l10n.notifLeadStatusTitle,
      body: l10n.notifLeadStatusBody(
        _leadStatusLabel(l10n, notification.status),
      ),
    ),
    WsEventType.newOffer => (
      title: l10n.notifNewOfferTitle,
      body: (notification.offerTitle?.trim().isNotEmpty ?? false)
          ? notification.offerTitle!.trim()
          : l10n.notifNewOfferBody,
    ),
    WsEventType.leadCreated => (
      title: l10n.notifLeadCreatedTitle,
      body: l10n.notifLeadCreatedBody,
    ),
    _ => (title: notification.title, body: notification.body),
  };
}

String _leadStatusLabel(AppLocalizations l10n, String? wire) {
  return switch (wire) {
    'new' => l10n.leadStatusNew,
    'contacted' => l10n.leadStatusContacted,
    'scheduled' => l10n.leadStatusScheduled,
    'visited' => l10n.leadStatusVisited,
    'won' => l10n.leadStatusWon,
    'lost' => l10n.leadStatusLost,
    null || '' => l10n.leadStatusNew,
    _ => wire,
  };
}
