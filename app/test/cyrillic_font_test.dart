import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/theme.dart';

import 'support.dart';

/// Real interface strings. The font file must contain every letter here.
const _samples = <String>[
  'Войти',
  'Регистрация компании',
  'ЁЙЩъыэюя',
  'o\u02BBg\u02BB',
  'ma\u02BClumot',
  'Ro\u2018yxatdan o\u2018tish',
];

void main() {
  test('Onest contains Cyrillic and Uzbek letters used on screen', () {
    final file = File('assets/fonts/Onest-Variable.ttf');
    expect(file.existsSync(), isTrue, reason: 'Onest-Variable.ttf is missing');
    final have = _cmapCodepoints(file.readAsBytesSync());
    final missing = <int>{
      for (final sample in _samples) ...sample.runes,
      for (final unit in 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.codeUnits) unit,
    }.where((code) => code > 32 && !have.contains(code)).toList()..sort();
    expect(
      missing,
      isEmpty,
      reason: missing.map((code) => '${String.fromCharCode(code)} U+${code.toRadixString(16).padLeft(4, '0').toUpperCase()}').join(' '),
    );

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: Onest'));
    expect(pubspec, contains('assets/fonts/Onest-Variable.ttf'));
    expect(pubspec, isNot(contains('PlusJakarta')));
    expect(pubspec, isNot(contains('fonts.gstatic.com')));
    expect(pubspec, isNot(contains('fonts.googleapis.com')));
    expect(AppTypography.fontFamily, 'Onest');

    final name = _nameRecord(file.readAsBytesSync(), 13);
    expect(name, contains('SIL Open Font License'));
  });

  testWidgets('sign-in and registration use Onest for Russian and Uzbek', (tester) async {
    await pumpIBuild(tester, size: const Size(1280, 900));
    expect(find.text('Войти'), findsOneWidget);
    expect(find.text('Подать заявку'), findsOneWidget);
    final context = tester.element(find.text('Войти'));
    expect(Theme.of(context).textTheme.bodyLarge?.fontFamily, 'Onest');
    expect(Theme.of(context).textTheme.labelLarge?.fontFamily, 'Onest');
    expect(DefaultTextStyle.of(context).style.fontFamily, 'Onest');

    await tester.tap(find.byKey(const Key('language-uz')));
    await tester.pumpAndSettle();
    final uzbek = find.text('Ariza yuborish');
    expect(uzbek, findsOneWidget);
    expect(DefaultTextStyle.of(tester.element(uzbek)).style.fontFamily, 'Onest');
  });
}

Set<int> _cmapCodepoints(Uint8List data) {
  final view = ByteData.sublistView(data);
  final tables = view.getUint16(4);
  var cmapOff = -1;
  for (var i = 0; i < tables; i++) {
    final rec = 12 + i * 16;
    final tag = String.fromCharCodes(data.sublist(rec, rec + 4));
    if (tag == 'cmap') cmapOff = view.getUint32(rec + 8);
  }
  expect(cmapOff, greaterThan(0));
  final points = <int>{};
  final subtables = view.getUint16(cmapOff + 2);
  for (var i = 0; i < subtables; i++) {
    final base = cmapOff + 4 + i * 8;
    final sub = cmapOff + view.getUint32(base + 4);
    final format = view.getUint16(sub);
    if (format == 4) {
      final segCount = view.getUint16(sub + 6) ~/ 2;
      final endAt = sub + 14;
      final startAt = endAt + segCount * 2 + 2;
      final deltaAt = startAt + segCount * 2;
      final rangeAt = deltaAt + segCount * 2;
      for (var s = 0; s < segCount; s++) {
        final start = view.getUint16(startAt + s * 2);
        final end = view.getUint16(endAt + s * 2);
        if (start == 0xFFFF) continue;
        final delta = view.getInt16(deltaAt + s * 2);
        final range = view.getUint16(rangeAt + s * 2);
        for (var code = start; code <= end; code++) {
          var glyph = 0;
          if (range == 0) {
            glyph = (code + delta) & 0xFFFF;
          } else {
            final pos = rangeAt + s * 2 + range + (code - start) * 2;
            glyph = view.getUint16(pos);
            if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
          }
          if (glyph != 0) points.add(code);
        }
      }
    } else if (format == 12) {
      final groups = view.getUint32(sub + 12);
      var pos = sub + 16;
      for (var g = 0; g < groups; g++) {
        final start = view.getUint32(pos);
        final end = view.getUint32(pos + 4);
        final glyph = view.getUint32(pos + 8);
        pos += 12;
        if (glyph == 0 && start == end) continue;
        for (var code = start; code <= end; code++) {
          points.add(code);
        }
      }
    }
  }
  return points;
}

String _nameRecord(Uint8List data, int nameId) {
  final view = ByteData.sublistView(data);
  final tables = view.getUint16(4);
  var nameOff = -1;
  for (var i = 0; i < tables; i++) {
    final rec = 12 + i * 16;
    final tag = String.fromCharCodes(data.sublist(rec, rec + 4));
    if (tag == 'name') nameOff = view.getUint32(rec + 8);
  }
  final count = view.getUint16(nameOff + 2);
  final storage = view.getUint16(nameOff + 4);
  for (var i = 0; i < count; i++) {
    final rec = nameOff + 6 + i * 12;
    final platform = view.getUint16(rec);
    final id = view.getUint16(rec + 6);
    if (platform != 3 || id != nameId) continue;
    final length = view.getUint16(rec + 8);
    final offset = view.getUint16(rec + 10);
    final start = nameOff + storage + offset;
    final units = <int>[];
    for (var b = 0; b < length; b += 2) {
      units.add(view.getUint16(start + b));
    }
    return String.fromCharCodes(units);
  }
  return '';
}
