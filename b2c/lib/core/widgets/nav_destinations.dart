import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// A primary navigation target, shared by the mobile pill bar and the desktop
/// sidebar so both stay in sync. [labelOf] resolves the localized label at
/// build time so this list can stay a `const`.
class NavDestination {
  const NavDestination({
    required this.labelOf,
    required this.icon,
    required this.route,
  });

  final String Function(AppLocalizations l10n) labelOf;
  final IconData icon;
  final String route;

  String label(BuildContext context) => labelOf(AppLocalizations.of(context));
}

const List<NavDestination> kNavDestinations = [
  NavDestination(
    labelOf: _homeLabel,
    icon: Icons.home_outlined,
    route: '/home',
  ),
  NavDestination(labelOf: _searchLabel, icon: Icons.search, route: '/map'),
  NavDestination(
    labelOf: _favoritesLabel,
    icon: Icons.attach_money,
    route: '/favorites',
  ),
  NavDestination(
    labelOf: _inquiriesLabel,
    icon: Icons.calendar_today_outlined,
    route: '/inquiries',
  ),
  NavDestination(
    labelOf: _settingsLabel,
    icon: Icons.settings_outlined,
    route: '/profile',
  ),
];

String _homeLabel(AppLocalizations l10n) => l10n.navHome;
String _searchLabel(AppLocalizations l10n) => l10n.navSearch;
String _favoritesLabel(AppLocalizations l10n) => l10n.navFavorites;
String _inquiriesLabel(AppLocalizations l10n) => l10n.navInquiries;
String _settingsLabel(AppLocalizations l10n) => l10n.navSettings;
