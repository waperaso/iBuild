import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/models.dart';

import 'support.dart';

void expectFullyVisible(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final rect = tester.getRect(finder);
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  expect(rect.width, greaterThan(8), reason: 'painted width');
  expect(rect.height, greaterThan(8), reason: 'painted height');
  expect(rect.left, greaterThanOrEqualTo(-1));
  expect(rect.top, greaterThanOrEqualTo(-1));
  expect(rect.right, lessThanOrEqualTo(size.width + 1));
  expect(rect.bottom, lessThanOrEqualTo(size.height + 1));
}

UserProfile _bankDemo() {
  return const UserProfile(
    id: 'user-bank',
    name: 'Д. Рахимов',
    login: 'a.observer',
    companyId: 'company-1',
    companyName: 'Навои Девелопмент',
    active: true,
    isDemo: true,
    memberships: [Membership(projectId: 'project-1', role: AppRole.observer)],
    bank: BankProfile(
      id: 'bank-1',
      name: 'Банк Навои',
      department: 'отдел проектного финансирования',
      role: 'specialist',
      title: 'Кредитный специалист',
      branch: 'Ташкент',
      queueCount: 2,
      trancheCount: 12,
      waitingAmount: '18740000000.00',
    ),
  );
}

void main() {
  testWidgets('a bank demo at 664px still shows the banner and the way out', (tester) async {
    await pumpIBuild(tester, user: _bankDemo(), size: const Size(664, 800));
    expectFullyVisible(tester, find.byKey(const Key('demo-banner')));
    expectFullyVisible(tester, find.byKey(const Key('demo-exit')));
    expect(find.text('Демо · Только просмотр'), findsOneWidget);
    expect(find.text('Выйти из демо'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a developer demo at the same width keeps the same strip', (tester) async {
    await pumpIBuild(
      tester,
      user: demoUser(AppRole.director, isDemo: true),
      size: const Size(664, 800),
    );
    expectFullyVisible(tester, find.byKey(const Key('demo-banner')));
    expectFullyVisible(tester, find.byKey(const Key('demo-exit')));
    expect(tester.takeException(), isNull);
  });
}
