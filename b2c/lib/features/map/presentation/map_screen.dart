import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/shell_tab_scope.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../discovery/presentation/widgets/filter_sheet.dart';
import '../../discovery/presentation/widgets/property_card.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../../discovery/providers/filters_providers.dart';

/// Map discovery screen: search field, project pins over an OSM base layer, and
/// a "Recommend for You" list. Mobile uses a bottom sheet; desktop uses a
/// side panel so the map can fill the remaining width.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    // Indexed stack keeps every tab mounted — skip FlutterMap + marker work
    // while another tab is selected so Home scroll / loadMore stays cheap.
    final tabIndex = ShellTabScope.maybeOf(context);
    if (tabIndex != null && tabIndex != ShellTabScope.mapTabIndex) {
      return ColoredBox(color: colors.background);
    }

    final projectsAsync = ref.watch(mapProjectsProvider);

    return ColoredBox(
      color: colors.background,
      child: AsyncValueView(
        value: projectsAsync,
        minHeight: double.infinity,
        onRetry: () => ref.invalidate(projectsProvider),
        builder: (context, projects) {
          if (context.isMobile) {
            return _MobileMapLayout(projects: projects);
          }
          return _DesktopMapLayout(projects: projects);
        },
      ),
    );
  }
}

class _MobileMapLayout extends StatelessWidget {
  const _MobileMapLayout({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: _ProjectMap(projects: projects)),
        const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: _MapSearchControls(),
          ),
        ),
        _RecommendSheet(projects: projects),
      ],
    );
  }
}

class _DesktopMapLayout extends StatelessWidget {
  const _DesktopMapLayout({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: _ProjectMap(projects: projects)),
              const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _MapSearchControls(maxWidth: 520),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(left: BorderSide(color: colors.outline)),
          ),
          child: _RecommendPanel(projects: projects),
        ),
      ],
    );
  }
}

class _ProjectMap extends StatefulWidget {
  const _ProjectMap({required this.projects});

  final List<Project> projects;

  @override
  State<_ProjectMap> createState() => _ProjectMapState();
}

class _ProjectMapState extends State<_ProjectMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final projects = widget.projects;
    final center = projects.isNotEmpty
        ? LatLng(projects.first.lat, projects.first.lng)
        : const LatLng(41.3111, 69.2797);

    // Keep markers tiny and skip clustering/district halos — those forced a
    // heavy rebuild on every pan/zoom on Flutter web.
    return RepaintBoundary(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 12,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'uz.ibuild.client',
            maxNativeZoom: 19,
            keepBuffer: 2,
            panBuffer: 1,
          ),
          MarkerLayer(
            markers: [
              for (final p in projects)
                Marker(
                  point: LatLng(p.lat, p.lng),
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  child: _MapPin(
                    project: p,
                    accent: colors.accent,
                    onAccent: colors.onAccent,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapSearchControls extends StatelessWidget {
  const _MapSearchControls({this.maxWidth});

  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SearchBar(),
        const SizedBox(height: AppSpacing.md),
        const _MapModeToggle(),
      ],
    );

    if (maxWidth == null) return controls;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: controls,
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(discoveryFiltersProvider).searchText,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final filters = ref.watch(discoveryFiltersProvider);
    return Row(
      children: [
        Expanded(
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            elevation: 2,
            shadowColor: colors.ink.withValues(alpha: 0.1),
            child: TextField(
              controller: _controller,
              onChanged: (v) =>
                  ref.read(discoveryFiltersProvider.notifier).setSearchText(v),
              decoration: InputDecoration(
                hintText: l10n.searchByLocations,
                prefixIcon: Icon(Icons.search, color: colors.inkMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Material(
          color: colors.surface,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: colors.ink.withValues(alpha: 0.1),
          child: IconButton(
            tooltip: l10n.filtersTitle,
            onPressed: () => showFilterSheet(context),
            icon: Badge(
              isLabelVisible: filters.hasSheetFilters,
              child: Icon(Icons.tune, color: colors.ink),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.project, required this.accent, required this.onAccent});

  final Project project;
  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/home/project/${project.id}'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
          border: Border.all(color: onAccent, width: 2),
        ),
      ),
    );
  }
}

class _MapModeToggle extends ConsumerWidget {
  const _MapModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(discoveryModeProvider);
    final items = {
      DiscoveryMode.buy: l10n.modeBuy,
      DiscoveryMode.rent: l10n.modeRent,
      DiscoveryMode.newBuilds: l10n.modeNewBuilds,
    };

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      elevation: 2,
      shadowColor: colors.ink.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in items.entries)
              GestureDetector(
                onTap: () =>
                    ref.read(discoveryModeProvider.notifier).set(entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: mode == entry.key
                        ? colors.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    entry.value,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: mode == entry.key
                          ? colors.onAccent
                          : colors.inkMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecommendPanel extends StatelessWidget {
  const _RecommendPanel({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          AppLocalizations.of(context).recommendForYou,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final p in projects)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: PropertyCard(
              project: p,
              onTap: () => context.go('/home/project/${p.id}'),
            ),
          ),
      ],
    );
  }
}

class _RecommendSheet extends StatelessWidget {
  const _RecommendSheet({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Room for the floating pill bottom nav (extendBody: true on mobile).
    final bottomInset = MediaQuery.paddingOf(context).bottom + 88;

    return DraggableScrollableSheet(
      initialChildSize: 0.38,
      minChildSize: 0.22,
      maxChildSize: 0.88,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.card),
            ),
            boxShadow: AppShadows.raised(colors.ink),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + bottomInset,
            ),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppLocalizations.of(context).recommendForYou,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final p in projects)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: PropertyCard(
                    project: p,
                    onTap: () => context.go('/home/project/${p.id}'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
