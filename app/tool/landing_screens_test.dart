// Render the real Flutter screens with sample data for the public product tour.
// From app/: IBUILD_SHOTS_DIR=/absolute/path flutter test tool/landing_screens_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild/app.dart';
import 'package:ibuild/models.dart';
import 'package:ibuild/session.dart';

import '../test/bank_fixtures.dart';
import '../test/support.dart';

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

  testWidgets('render landing screenshots', skip: output == null, (tester) async {
    const size = Size(1280, 760);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final frame = GlobalKey();

    Future<void> start(FakeApi api) async {
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
    }

    Future<void> shot(String route, String name, Key visible, {Future<void> Function()? prepare}) async {
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
      await tester.pumpAndSettle();
      expect(find.byKey(visible), findsOneWidget);
      if (prepare != null) await prepare();
      await tester.pumpAndSettle();
      final boundary = frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
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

    await start(FakeApi(
      user: const UserProfile(
        id: 'user-1', name: 'Н. Юсупова', login: 'sample.director',
        companyId: 'company-1', companyName: 'Навои Девелопмент', active: true,
        memberships: [Membership(projectId: 'project-1', role: AppRole.director)],
      ),
      projects: [demoProject(AppRole.director)],
      lines: const [
        BudgetLine(
          id: 'line-1', title: 'Работы нулевого цикла',
          amount: '3500000000.00', available: '2600000000.00',
          contractorFirmId: 'firm-1', contractorFirmName: 'Монолит Строй Сервис',
        ),
      ],
    ));
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/projects/project-1');
    await tester.pumpAndSettle();
    await shot('/requests/new?project=project-1', 'request', const Key('request-form'),
        prepare: () async {
      await tester.enterText(find.byKey(const Key('request-price')), '2260000000');
      await tester.enterText(find.byKey(const Key('request-why')), 'Фундамент и материалы на площадке, секция А.');
      FocusManager.instance.primaryFocus?.unfocus();
    });

    await start(FakeApi(user: bankUser())
      ..jsonAnswers['/api/bank/inspections'] = {
        'items': [
          {
            'id': 'i-navoi',
            'project_id': 'project-1',
            'project_name': 'ЖК Навои',
            'tranche_no': 2,
            'kind': 'control',
            'status': 'done',
            'scheduled': '2026-10-23',
            'completed': '2026-10-23',
            'expert': 'А. Каримов',
            'risk': 'watch',
            'recommendation': 'issue',
            'note': 'Объём работ по фундаменту подтверждён частично.',
          },
        ],
        'counts': {'planned': 0, 'done': 1, 'overdue': 0},
        'canPlan': true,
        'canComplete': false,
      });
    await shot('/bank/inspections', 'inspection', const Key('bank-inspections-frame'),
        prepare: () async {
      await tester.tap(find.byKey(const Key('inspections-filter-done')));
      await tester.pumpAndSettle();
      expect(find.text('Объём работ по фундаменту подтверждён частично.'), findsOneWidget);
    });
    await shot('/bank/tranches/t-navoi', 'review', const Key('bank-tranche-frame'));

    await start(FakeApi(user: const UserProfile(
      id: 'user-head', name: 'М. Усманова', login: 'sample.head',
      companyId: 'bank-1', companyName: 'Банк Навои', active: true, memberships: [],
      bank: BankProfile(
        id: 'bank-1', name: 'Банк Навои', department: 'отдел проектного финансирования',
        role: 'head', title: 'Начальник отдела', branch: 'Ташкент',
        queueCount: 2, trancheCount: 12, waitingAmount: '18740000000.00',
      ),
    )));
    await shot('/bank/tranches/t-navoi/approval', 'approval', const Key('bank-approval-frame'));
  });
}
