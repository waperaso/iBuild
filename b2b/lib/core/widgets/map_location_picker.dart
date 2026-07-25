import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import '../../l10n/gen/app_localizations.dart';

/// Default map centre — central Tashkent.
const kDefaultMapCenter = LatLng(41.3111, 69.2797);

/// Zoom range for the picker's map and its vertical zoom slider.
const _kMapMinZoom = 3.0;
const _kMapMaxZoom = 18.0;

/// Interactive OSM map for picking a single geographic point — tap the map,
/// or type exact latitude/longitude coordinates directly.
class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({
    super.key,
    required this.location,
    required this.onLocationChanged,
    this.height = 220,
    this.interactive = true,
  });

  final LatLng location;
  final ValueChanged<LatLng> onLocationChanged;
  final double height;
  final bool interactive;

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final _mapController = MapController();
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  String? _coordsError;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(
      text: widget.location.latitude.toStringAsFixed(6),
    );
    _lngController = TextEditingController(
      text: widget.location.longitude.toStringAsFixed(6),
    );
  }

  @override
  void didUpdateWidget(MapLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location) {
      _syncFieldsFromLocation();
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _syncFieldsFromLocation() {
    _latController.text = widget.location.latitude.toStringAsFixed(6);
    _lngController.text = widget.location.longitude.toStringAsFixed(6);
  }

  void _onMapTap(LatLng point) {
    widget.onLocationChanged(point);
    setState(() {
      _coordsError = null;
      _syncFieldsFromLocation();
    });
  }

  void _applyTypedCoordinates() {
    final l10n = AppLocalizations.of(context);
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null ||
        lng == null ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      setState(() => _coordsError = l10n.mapLocationInvalidCoordinates);
      return;
    }
    final point = LatLng(lat, lng);
    setState(() => _coordsError = null);
    widget.onLocationChanged(point);
    _mapController.move(point, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.mapLocationTapHint,
          style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.location,
                    initialZoom: 13,
                    minZoom: _kMapMinZoom,
                    maxZoom: _kMapMaxZoom,
                    onTap: widget.interactive
                        ? (_, point) => _onMapTap(point)
                        : null,
                    interactionOptions: InteractionOptions(
                      // This picker always sits inside a scrollable form,
                      // never full-screen. `scrollWheelZoom` claims the
                      // mouse wheel the instant the cursor is over the map —
                      // flutter_map registers with the same
                      // [PointerSignalResolver] the page's own `Scrollable`
                      // uses, and wins because it's deeper in the hit-test
                      // order, so the page scroll just stops dead as soon as
                      // the cursor crosses onto the map. Dropping that one
                      // flag stops it from registering at all, so the
                      // ancestor scrollable keeps handling the wheel —
                      // pinch-zoom, drag-to-pan and tap-to-pick still work
                      // fine without it, and the slider below covers precise
                      // zooming without the mouse wheel at all.
                      flags: widget.interactive
                          ? InteractiveFlag.all &
                                ~InteractiveFlag.scrollWheelZoom
                          : InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'uz.ibuild.b2b',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: widget.location,
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_on,
                            color: colors.accentSecondary,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: AppSpacing.sm,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _VerticalZoomSlider(mapController: _mapController),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.mapLocationManualHint,
          style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _latController,
                enabled: widget.interactive,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[-\d.]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.mapLocationLatitudeLabel,
                  isDense: true,
                ),
                onSubmitted: (_) => _applyTypedCoordinates(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _lngController,
                enabled: widget.interactive,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[-\d.]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.mapLocationLongitudeLabel,
                  isDense: true,
                ),
                onSubmitted: (_) => _applyTypedCoordinates(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.tonal(
              onPressed: widget.interactive ? _applyTypedCoordinates : null,
              child: Text(l10n.mapLocationApplyCoordinates),
            ),
          ],
        ),
        if (_coordsError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _coordsError!,
            style: textTheme.labelSmall?.copyWith(color: colors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.mapLocationCoordinates(
            widget.location.latitude.toStringAsFixed(5),
            widget.location.longitude.toStringAsFixed(5),
          ),
          style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
        ),
      ],
    );
  }
}

/// Floating vertical zoom slider for the map — an explicit way to zoom
/// in/out that doesn't need the mouse wheel (disabled here, see the
/// `interactionOptions` comment above) or a precise pinch gesture.
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

    return Material(
      color: colors.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      elevation: 2,
      shadowColor: colors.ink.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.mapLocationZoomIn,
              iconSize: 14,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(
                width: 28,
                height: 28,
              ),
              padding: EdgeInsets.zero,
              onPressed: zoom < _kMapMaxZoom ? () => _setZoom(zoom + 1) : null,
              icon: Icon(Icons.add, color: colors.ink),
            ),
            SizedBox(
              width: 24,
              height: 96,
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: zoom,
                    min: _kMapMinZoom,
                    max: _kMapMaxZoom,
                    onChanged: _setZoom,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.mapLocationZoomOut,
              iconSize: 14,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(
                width: 28,
                height: 28,
              ),
              padding: EdgeInsets.zero,
              onPressed: zoom > _kMapMinZoom ? () => _setZoom(zoom - 1) : null,
              icon: Icon(Icons.remove, color: colors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
