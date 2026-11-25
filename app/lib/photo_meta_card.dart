import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n.dart';
import 'models.dart';
import 'picked_file.dart';
import 'theme.dart';

/// Displays forensic verification details for an uploaded tranche photo:
/// verification status, capture source (live camera vs gallery upload),
/// SHA-256 checksum, EXIF camera/timestamp, EXIF & device geotags, distance to site,
/// and anti-spoofing/duplicate flags.
class PhotoMetaPanel extends StatelessWidget {
  const PhotoMetaPanel({super.key, required this.file});

  final RequestFile file;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    final muted = small?.copyWith(color: colors.inkMuted);

    final (statusLabel, statusColor) = switch (file.verifyStatus) {
      'verified' => (
          copy.pick('Фото подтверждено', 'Photo verified', 'Foto tasdiqlangan'),
          colors.success,
        ),
      'alert' => (
          copy.pick('Требует проверки', 'Needs review', 'Tekshiruv talab qiladi'),
          colors.danger,
        ),
      'warning' => (
          copy.pick('Есть замечания', 'Warnings', 'Izohlar bor'),
          colors.warning,
        ),
      _ => (
          copy.pick('Без проверки', 'Unverified', 'Tekshirilmagan'),
          colors.inkMuted,
        ),
    };

    final sourceLabel = file.captureSource == 'camera'
        ? copy.pick('Снято на камеру', 'Captured on site', 'Kameraga olingan')
        : copy.pick('Загружено из файла', 'Uploaded from file', 'Fayldan yuklangan');

    final shortHash = file.sha256.length >= 16
        ? '${file.sha256.substring(0, 12)}…${file.sha256.substring(file.sha256.length - 6)}'
        : file.sha256;

    final distanceText = file.distanceM == null
        ? null
        : file.distanceM! >= 1000
            ? '${(file.distanceM! / 1000).toStringAsFixed(1)} ${copy.pick('км от объекта', 'km from site', 'km obyektdan')}'
            : '${file.distanceM} ${copy.pick('м от объекта', 'm from site', 'm obyektdan')}';

    final visibleFlags = file.verifyFlags.where((f) => f != 'uploaded_from_gallery').toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Badge(label: statusLabel, color: statusColor),
                _Badge(
                  label: sourceLabel,
                  color: file.captureSource == 'camera' ? colors.accent : colors.inkMuted,
                  icon: file.captureSource == 'camera'
                      ? Icons.photo_camera_outlined
                      : Icons.photo_library_outlined,
                ),
                if (distanceText != null)
                  _Badge(
                    label: distanceText,
                    color: file.verifyFlags.contains('far_from_site')
                        ? colors.danger
                        : colors.inkMuted,
                    icon: Icons.place_outlined,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (file.sha256.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'SHA-256: $shortHash',
                      style: small?.copyWith(fontFamily: 'monospace', color: colors.ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: file.sha256));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            copy.pick('SHA-256 скопирован', 'SHA-256 copied', 'SHA-256 nusxalandi'),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Icon(Icons.copy_outlined, size: 14, color: colors.inkMuted),
                    ),
                  ),
                ],
              ),
            if (file.hasExifGeo)
              Text(
                'EXIF GPS: ${file.exifLat!.toStringAsFixed(6)}, ${file.exifLon!.toStringAsFixed(6)}'
                '${file.exifHeading != null ? ' · ${file.exifHeading!.round()}°' : ''}',
                style: small,
              ),
            if (file.hasDeviceGeo)
              Text(
                '${copy.pick('Геолокация устройства', 'Device GPS', 'Qurilma GPS')}: '
                '${file.gpsLat!.toStringAsFixed(6)}, ${file.gpsLon!.toStringAsFixed(6)}'
                '${file.gpsAccuracy != null ? ' (±${file.gpsAccuracy!.round()} м)' : ''}'
                '${file.gpsHeading != null ? ' · ${file.gpsHeading!.round()}°' : ''}',
                style: muted,
              ),
            if (!file.hasAnyGeo)
              Text(
                copy.pick('Геотеги не найдены', 'No geotags found', 'Geoteglar topilmadi'),
                style: small?.copyWith(color: colors.warning),
              ),
            if (file.cameraLabel.isNotEmpty || file.exifTakenAt != null)
              Text(
                [
                  if (file.cameraLabel.isNotEmpty) 'EXIF: ${file.cameraLabel}',
                  if (file.exifTakenAt != null) _fmtIso(file.exifTakenAt!),
                ].join(' · '),
                style: muted,
              )
            else if (file.capturedAt != null)
              Text(
                '${copy.pick('Зафиксировано', 'Captured', 'Qayd etilgan')}: ${_fmtIso(file.capturedAt!)}',
                style: muted,
              ),
            if (visibleFlags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              for (final flag in visibleFlags)
                Text(
                  '• ${_flagLabel(copy, flag)}',
                  style: small?.copyWith(
                    color: _isAlertFlag(flag) ? colors.danger : colors.warning,
                    fontWeight: _isAlertFlag(flag) ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact summary shown immediately after picking/capturing a photo before upload.
class PendingPhotoMetaStrip extends StatelessWidget {
  const PendingPhotoMetaStrip({super.key, required this.picked});

  final PickedFile picked;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final meta = picked.meta;
    final isCamera = meta?.captureSource == 'camera';
    final sizeKb = (picked.bytes.length / 1024).toStringAsFixed(0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Badge(
                  label: isCamera
                      ? copy.pick('Снято на камеру', 'Captured on site', 'Kameraga olingan')
                      : copy.pick('Загружено из файла', 'Uploaded from file', 'Fayldan yuklangan'),
                  color: isCamera ? colors.success : colors.accent,
                  icon: isCamera ? Icons.photo_camera_outlined : Icons.photo_library_outlined,
                ),
                Text(
                  '${picked.name} ($sizeKb KB)',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (meta != null && meta.hasGeo)
              Text(
                'GPS: ${meta.gpsLat!.toStringAsFixed(6)}, ${meta.gpsLon!.toStringAsFixed(6)}'
                '${meta.gpsAccuracy != null ? ' (±${meta.gpsAccuracy!.round()} м)' : ''}'
                '${meta.gpsHeading != null ? ' · ${meta.gpsHeading!.round()}°' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(color: colors.success),
              )
            else
              Text(
                copy.pick(
                  'EXIF, геотеги и контрольная сумма SHA-256 будут извлечены и проверены при сохранении.',
                  'EXIF, geotags and SHA-256 checksum will be extracted and verified on save.',
                  'EXIF, geoteglar va SHA-256 nazorat summasi saqlashda tekshiriladi.',
                ),
                style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isAlertFlag(String flag) =>
    flag == 'duplicate_checksum' || flag == 'far_from_site' || flag == 'geo_mismatch';

String _flagLabel(AppCopy copy, String flag) {
  return switch (flag) {
    'duplicate_checksum' => copy.pick(
        'Дубликат фото: такой же SHA-256 уже использовался ранее',
        'Duplicate photo: identical SHA-256 was already uploaded before',
        'Takroriy foto: aynan shu SHA-256 avval yuklangan',
      ),
    'far_from_site' => copy.pick(
        'Координаты фото далеко от объекта (> 1,5 км)',
        'Photo coordinates are far from the project site (> 1.5 km)',
        'Foto koordinatalari obyektdan uzoqda (> 1,5 km)',
      ),
    'geo_mismatch' => copy.pick(
        'Расхождение между EXIF GPS и геолокацией устройства',
        'Mismatch between EXIF GPS and device geolocation',
        'EXIF GPS va qurilma geolokatsiyasi mos kelmaydi',
      ),
    'stale_photo' => copy.pick(
        'Дата съёмки в EXIF старше 14 дней',
        'EXIF capture date is older than 14 days',
        'EXIF suratga olish sanasi 14 kundan eski',
      ),
    'no_exif' => copy.pick(
        'В файле нет EXIF-метаданных камеры',
        'No camera EXIF metadata found in the image',
        'Faylda kamera EXIF metama’lumotlari yo‘q',
      ),
    'no_geo' => copy.pick(
        'Отсутствуют геотеги и геолокация устройства',
        'Missing both EXIF geotags and device geolocation',
        'Geoteglar va qurilma geolokatsiyasi mavjud emas',
      ),
    _ => flag,
  };
}

String _fmtIso(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final local = parsed.toUtc().add(const Duration(hours: 5));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
}
