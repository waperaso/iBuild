import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'bank_card.dart' show bankCents;
import 'bank_rules.dart' show bankMillions;

/// Report files. The same table the screen shows goes to CSV, XLSX and PDF, so
/// the file and the screen cannot disagree.

class ReportColumn {
  const ReportColumn(this.key, this.label, {this.kind = 'text'});

  final String key;
  final String label;

  /// text, money, percent, date or int.
  final String kind;

  Map<String, Object?> toJson() => {'key': key, 'label': label, 'kind': kind};
}

String reportCell(ReportColumn column, Object? value) {
  if (value == null) return '';
  switch (column.kind) {
    case 'money':
      return bankMillions(bankCents(value.toString()));
    case 'percent':
      return '$value%';
    case 'date':
      final text = value.toString();
      return RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(text)
          ? '${text.substring(8, 10)}.${text.substring(5, 7)}.${text.substring(0, 4)}'
          : text;
    default:
      return value.toString();
  }
}

String _csvField(String value) {
  final safe = RegExp(r'^[=+\-@\t\r]').hasMatch(value) ? "'$value" : value;
  return '"${safe.replaceAll('"', '""')}"';
}

Uint8List reportCsv(List<ReportColumn> columns, List<Map<String, Object?>> rows) {
  final out = StringBuffer('\u{feff}');
  out.writeln(columns.map((column) => _csvField(column.label)).join(';'));
  for (final row in rows) {
    out.writeln(columns.map((column) => _csvField(reportCell(column, row[column.key]))).join(';'));
  }
  return Uint8List.fromList(utf8.encode(out.toString()));
}

String _xml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '');

String _columnName(int index) {
  var n = index;
  var name = '';
  do {
    name = String.fromCharCode(65 + n % 26) + name;
    n = n ~/ 26 - 1;
  } while (n >= 0);
  return name;
}

Uint8List reportXlsx(String title, List<ReportColumn> columns, List<Map<String, Object?>> rows) {
  String text(int col, int row, String value, {bool bold = false}) =>
      '<c r="${_columnName(col)}$row" t="inlineStr"${bold ? ' s="1"' : ''}><is><t xml:space="preserve">${_xml(value)}</t></is></c>';
  final sheet = StringBuffer(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>',
  );
  sheet.write('<row r="1">');
  for (var c = 0; c < columns.length; c++) {
    sheet.write(text(c, 1, columns[c].label, bold: true));
  }
  sheet.write('</row>');
  for (var r = 0; r < rows.length; r++) {
    final number = r + 2;
    sheet.write('<row r="$number">');
    for (var c = 0; c < columns.length; c++) {
      final column = columns[c];
      final value = rows[r][column.key];
      if (value == null) continue;
      if (column.kind == 'money') {
        // Millions as a number, so the sheet can be summed.
        final cents = bankCents(value.toString());
        final tenths = (cents + BigInt.from(5000000)) ~/ BigInt.from(10000000);
        sheet.write('<c r="${_columnName(c)}$number"><v>${tenths ~/ BigInt.from(10)}.${tenths % BigInt.from(10)}</v></c>');
      } else if (column.kind == 'int' && int.tryParse(value.toString()) != null) {
        sheet.write('<c r="${_columnName(c)}$number"><v>$value</v></c>');
      } else {
        sheet.write(text(c, number, reportCell(column, value)));
      }
    }
    sheet.write('</row>');
  }
  sheet.write('</sheetData></worksheet>');

  const styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
      '<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs></styleSheet>';
  final name = _xml(title.length > 31 ? title.substring(0, 31) : title).replaceAll(RegExp(r'[\\/*?:\[\]]'), ' ');
  final files = <String, String>{
    '[Content_Types].xml': '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '</Types>',
    '_rels/.rels': '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
    'xl/workbook.xml': '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets><sheet name="$name" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels': '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>',
    'xl/styles.xml': styles,
    'xl/worksheets/sheet1.xml': sheet.toString(),
  };
  final archive = Archive();
  files.forEach((path, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

pw.Font? _regular;
pw.Font? _bold;

pw.Font _font(String file) {
  final candidates = ['assets/fonts/$file', '/app/assets/fonts/$file'];
  for (final path in candidates) {
    final font = File(path);
    if (font.existsSync()) return pw.Font.ttf(ByteData.view(font.readAsBytesSync().buffer));
  }
  throw StateError('Font $file is missing, PDF files cannot be made');
}

Future<Uint8List> reportPdf(
  String title,
  String subtitle,
  List<ReportColumn> columns,
  List<Map<String, Object?>> rows,
) async {
  final regular = _regular ??= _font('Roboto-Regular.ttf');
  final bold = _bold ??= _font('Roboto-Bold.ttf');
  final document = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));
  final data = [
    for (final row in rows) [for (final column in columns) reportCell(column, row[column.key])],
  ];
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 16)),
        pw.SizedBox(height: 4),
        pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: [for (final column in columns) column.label],
          data: data,
          headerStyle: pw.TextStyle(font: bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignments: {
            for (var i = 0; i < columns.length; i++)
              i: columns[i].kind == 'text' ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
          },
        ),
      ],
    ),
  );
  return Uint8List.fromList(await document.save());
}
