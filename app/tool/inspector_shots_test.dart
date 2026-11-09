// Render the site inspector's (technical supervisor's) screens with sample data,
// in both themes, so the desktop layout can be judged by eye.
// From app/: IBUILD_SHOTS_DIR=/absolute/path flutter test tool/inspector_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild/app.dart';
import 'package:ibuild/session.dart';

import '../test/inspector_fixtures.dart';

void main() {
  final output = Platform.environment['IBUILD_SHOTS_DIR'];
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (output == null) return;
    Future<void> loadFont(String family, String path) async {
      await (FontLoader(family)
            ..addFont(File(path).readAsBytes().then(ByteData.sublistView)))
          .load();
    }

    await loadFont('Onest', 'assets/fonts/Onest-Variable.ttf');
    await loadFont('MaterialIcons', 'build/web/assets/fonts/MaterialIcons-Regular.otf');
  });

  testWidgets('render the inspector screens', skip: output == null, (tester) async {
    const size = Size(1280, 810);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final frame = GlobalKey();

    final api = InspectorApi();
    final session = SessionController(api);
    await session.restore();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      RepaintBoundary(
        key: frame,
        child: IBuildApp(key: UniqueKey(), api: api, session: session, restoreOnStart: false),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      final boundary = frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('$output/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
    }

    Future<void> go(String route) async {
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
      await tester.pumpAndSettle();
    }

    const pages = <(String, String)>[
      ('/home', 'home'),
      ('/queue', 'queue'),
      ('/inspections', 'inspections'),
      ('/requests', 'requests'),
      ('/requests/req-1', 'tranche'),
      ('/projects', 'projects'),
      ('/budget', 'budget'),
      ('/documents', 'documents'),
      ('/people', 'people'),
    ];

    // The repo ships with Russian copy; English reads the same layout and is
    // easier to compare against the bank and developer shots.
    await tester.tap(find.byKey(const Key('language-en')).first);
    await tester.pumpAndSettle();

    for (final theme in ['light', 'dark']) {
      for (final page in pages) {
        await go(page.$1);
        await shot('${page.$2}-$theme');
      }
      if (theme == 'light') {
        await go('/home');
        await tester.tap(find.byKey(const Key('theme-switch')).first);
        await tester.pumpAndSettle();
      }
    }
  });
}
