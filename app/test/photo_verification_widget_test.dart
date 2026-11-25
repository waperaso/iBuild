import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/l10n.dart';
import 'package:ibuild/models.dart';
import 'package:ibuild/photo_meta_card.dart';
import 'package:ibuild/theme.dart';
import 'package:ibuild/widgets.dart';

import 'bank_fixtures.dart';
import 'support.dart';

void main() {
  testWidgets('PhotoMetaPanel renders verified EXIF, SHA-256, geolocation and distance', (tester) async {
    const file = RequestFile(
      id: 'photo-1',
      kind: 'photo',
      contentType: 'image/jpeg',
      sizeBytes: 204800,
      sha256: 'a3f1b2c4d5e6f708192a3b4c5d6e7f8091a2b3c4d5e6f708192a3b4c5d6e7f80',
      captureSource: 'camera',
      capturedAt: '2026-11-25T09:55:00Z',
      gpsLat: 41.311100,
      gpsLon: 69.240580,
      gpsAccuracy: 12.0,
      gpsHeading: 185.0,
      exifLat: 41.311120,
      exifLon: 69.240590,
      exifTakenAt: '2026-11-25T09:54:00Z',
      cameraMake: 'Apple',
      cameraModel: 'iPhone 15 Pro',
      distanceM: 18,
      verifyStatus: 'verified',
      verifyFlags: [],
    );

    final locale = LocaleController()..select(AppLanguage.ru);
    await tester.pumpWidget(
      LocaleScope(
        controller: locale,
        child: MaterialApp(
          theme: buildIBuildTheme(IBuildColors.light),
          home: const Scaffold(body: PhotoMetaPanel(file: file)),
        ),
      ),
    );

    expect(find.text('Фото подтверждено'), findsOneWidget);
    expect(find.text('Снято на камеру'), findsOneWidget);
    expect(find.textContaining('Apple iPhone 15 Pro'), findsOneWidget);
    expect(find.textContaining('SHA-256: a3f1b2c4d5e6'), findsOneWidget);
    expect(find.textContaining('41.311120, 69.240590'), findsOneWidget);
    expect(find.textContaining('18 м от объекта'), findsOneWidget);
  });

  testWidgets('PhotoMetaPanel renders anti-spoofing alert flags for duplicate and far photo', (tester) async {
    const file = RequestFile(
      id: 'photo-dup',
      kind: 'photo',
      contentType: 'image/jpeg',
      sizeBytes: 150000,
      sha256: 'deadbeef00112233445566778899aabbccddeeff00112233445566778899aabb',
      captureSource: 'upload',
      distanceM: 4200,
      verifyStatus: 'alert',
      verifyFlags: ['duplicate_checksum', 'far_from_site', 'geo_mismatch'],
      duplicateOfFileId: 'photo-orig',
    );

    final locale = LocaleController()..select(AppLanguage.ru);
    await tester.pumpWidget(
      LocaleScope(
        controller: locale,
        child: MaterialApp(
          theme: buildIBuildTheme(IBuildColors.light),
          home: const Scaffold(body: PhotoMetaPanel(file: file)),
        ),
      ),
    );

    expect(find.text('Требует проверки'), findsOneWidget);
    expect(find.textContaining('4.2 км от объекта'), findsOneWidget);
    expect(find.textContaining('Дубликат фото'), findsOneWidget);
    expect(find.textContaining('Координаты фото далеко от объекта'), findsOneWidget);
    expect(find.textContaining('Расхождение между EXIF GPS и геолокацией устройства'), findsOneWidget);
  });

  testWidgets('RequestFormScreen shows camera + upload actions and blocks submit without photo', (tester) async {
    await pumpIBuild(tester, user: demoUser(AppRole.director));
    await tester.tap(find.byKey(const Key('nav-requests')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-request')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('request-photo-camera')), findsOneWidget);
    expect(find.byKey(const Key('request-photo')), findsOneWidget);
    expect(find.text('Сделать фото'), findsOneWidget);
    expect(find.text('Загрузить фото'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('request-price')), '100');
    await tester.enterText(find.byKey(const Key('request-why')), 'Монтаж перекрытия');
    await tester.pumpAndSettle();

    // Save button remains disabled while no site photo is captured or uploaded.
    final button = tester.widget<PrimaryButton>(find.byKey(const Key('save-draft')));
    expect(button.onPressed, isNull);
  });

  testWidgets('BankTrancheScreen displays site photos with EXIF and SHA-256 forensics', (tester) async {
    final api = await pumpIBuild(tester, user: bankUser(), projects: const []);
    api.bankCard = sampleBankTranche(
      sitePhotos: const [
        RequestFile(
          id: 'site-photo-1',
          kind: 'photo',
          contentType: 'image/jpeg',
          sizeBytes: 184320,
          sha256: '11223344556677889900aabbccddeeff11223344556677889900aabbccddeeff',
          captureSource: 'camera',
          exifLat: 41.311100,
          exifLon: 69.240580,
          cameraMake: 'Apple',
          cameraModel: 'iPhone 15 Pro',
          distanceM: 25,
          verifyStatus: 'verified',
          verifyFlags: [],
          url: '/api/bank/tranches/t-navoi/photos/site-photo-1',
        ),
      ],
    );
    await tester.tap(find.byKey(const Key('bank-open-t-navoi')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bank-site-photos')), findsOneWidget);
    expect(find.textContaining('Фотофиксация с объекта (1)'), findsOneWidget);
    expect(find.textContaining('SHA-256: 112233445566'), findsOneWidget);
    expect(find.textContaining('Apple iPhone 15 Pro'), findsOneWidget);
  });
}
