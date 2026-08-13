import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/scroll_tuning.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/shell_tab_scope.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../ai/presentation/widgets/ai_search_bar.dart';
import '../../ai/presentation/widgets/ai_search_panel.dart';
import '../../ai/providers/ai_search_providers.dart';
import '../../discovery/presentation/widgets/property_card.dart';
import '../../discovery/providers/discovery_providers.dart';

/// Zoom range shared by the map's gestures and its [_VerticalZoomSlider] —
/// keeps the slider's travel meaningful (whole app never needs continent- or
/// street-level extremes) and matches the tile layer's `maxNativeZoom`.
const _kMapMinZoom = 3.0;
const _kMapMaxZoom = 18.0;

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

class _MobileMapLayout extends StatefulWidget {
  const _MobileMapLayout({required this.projects});

  final List<Project> projects;

  @override
  State<_MobileMapLayout> createState() => _MobileMapLayoutState();
}

class _MobileMapLayoutState extends State<_MobileMapLayout> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: _ProjectMap(
            projects: widget.projects,
            mapController: _mapController,
          ),
        ),
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
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: _VerticalZoomSlider(mapController: _mapController),
          ),
        ),
        _RecommendSheet(projects: widget.projects),
      ],
    );
  }
}

class _DesktopMapLayout extends StatefulWidget {
  const _DesktopMapLayout({required this.projects});

  final List<Project> projects;

  @override
  State<_DesktopMapLayout> createState() => _DesktopMapLayoutState();
}

class _DesktopMapLayoutState extends State<_DesktopMapLayout> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

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
              Positioned.fill(
                child: _ProjectMap(
                  projects: widget.projects,
                  mapController: _mapController,
                ),
              ),
              const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _MapSearchControls(maxWidth: 520),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: _VerticalZoomSlider(mapController: _mapController),
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
          child: _RecommendPanel(projects: widget.projects),
        ),
      ],
    );
  }
}

class _ProjectMap extends StatelessWidget {
  const _ProjectMap({required this.projects, required this.mapController});

  final List<Project> projects;
  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final center = projects.isNotEmpty
        ? LatLng(projects.first.lat, projects.first.lng)
        : const LatLng(41.3111, 69.2797);

    // Keep markers tiny and skip clustering/district halos — those forced a
    // heavy rebuild on every pan/zoom on Flutter web.
    return RepaintBoundary(
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 12,
          minZoom: _kMapMinZoom,
          maxZoom: _kMapMaxZoom,
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

/// Vertical zoom control (+/− and slider).
class _VerticalZoomSlider extends StatefulWidget {
  const _VerticalZoomSlider({required this.mapController});

  final MapController mapController;

  @override
  State<_VerticalZoomSlider> createState() => _VerticalZoomSliderState();
}

class _VerticalZoomSliderState extends State<_VerticalZoomSlider> {
  late double _zoom;
  StreamSubscription<MapEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _zoom = widget.mapController.camera.zoom;
    // Keep the slider's thumb in sync when the zoom changes some other way
    // (pinch, double-tap, or the coordinate fields), not just its own drag.
    _subscription = widget.mapController.mapEventStream.listen((_) {
      final next = widget.mapController.camera.zoom;
      if (mounted && next != _zoom) setState(() => _zoom = next);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _setZoom(double value) {
    final clamped = value.clamp(_kMapMinZoom, _kMapMaxZoom);
    widget.mapController.move(widget.mapController.camera.center, clamped);
    setState(() => _zoom = clamped);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final zoom = _zoom.clamp(_kMapMinZoom, _kMapMaxZoom);

    return VerticalSliderControl(
      value: zoom,
      min: _kMapMinZoom,
      max: _kMapMaxZoom,
      colors: colors,
      onChanged: _setZoom,
      onIncrease: zoom < _kMapMaxZoom ? () => _setZoom(zoom + 1) : null,
      onDecrease: zoom > _kMapMinZoom ? () => _setZoom(zoom - 1) : null,
      increaseTooltip: l10n.mapZoomIn,
      decreaseTooltip: l10n.mapZoomOut,
    );
  }
}

class _MapSearchControls extends ConsumerWidget {
  const _MapSearchControls({this.maxWidth});

  final double? maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveSearch = ref.watch(
      aiSearchProvider.select((s) => s.phase != AiSearchPhase.idle),
    );

    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _MapSearchSurface(child: AiSearchBar()),
        if (hasActiveSearch)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: const SingleChildScrollView(
                child: _MapSearchSurface(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: AiSearchPanel(showResultCards: false),
                ),
              ),
            ),
          ),
      ],
    );

    if (maxWidth == null) return controls;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: controls,
    );
  }
}

/// Wraps AI search widgets in an opaque, shadowed surface so they stay
/// legible over the map tiles (the shared [AiSearchBar]/[AiSearchPanel] are
/// flat by default since discovery already sits on an opaque background).
class _MapSearchSurface extends StatelessWidget {
  const _MapSearchSurface({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      elevation: 2,
      shadowColor: colors.ink.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
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

class _RecommendPanel extends StatelessWidget {
  const _RecommendPanel({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      scrollCacheExtent: kScrollCacheExtent120,
      itemCount: projects.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(l10n.recommendForYou, style: textTheme.titleLarge),
          );
        }
        final p = projects[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: PropertyCard(
            project: p,
            onTap: () => context.go('/home/project/${p.id}'),
          ),
        );
      },
    );
  }
}

class _RecommendSheet extends StatelessWidget {
  const _RecommendSheet({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
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
          child: ListView.builder(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + bottomInset,
            ),
            scrollCacheExtent: kScrollCacheExtent120,
            itemCount: projects.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
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
                      l10n.recommendForYou,
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              }
              final p = projects[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: PropertyCard(
                  project: p,
                  onTap: () => context.go('/home/project/${p.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
