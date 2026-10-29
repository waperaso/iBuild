import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/money.dart';

void main() {
  test('money stays a decimal string and refuses numbers', () {
    expect(moneyAsShown('12500000.00'), '12\u00a0500\u00a0000.00');
    expect(moneyAsShown('100.50'), '100.50');
    expect(moneyAsShown(null), '—');
    expect(moneyAsShown(''), '—');
    expect(moneyAsShown(12.5), '—');
  });

  test('bank millions keep one decimal', () {
    expect(moneyMillions('18740000000.00'), '18 740,0');
    expect(moneyMillions('2083900000.00'), '2 083,9');
    expect(moneyMillions('0.00'), '0,0');
  });

  test('bank millions round half up instead of cutting the tail', () {
    expect(moneyMillions('2083949999.99'), '2 083,9');
    expect(moneyMillions('2083950000.00'), '2 084,0');
    expect(moneyMillions('49999.99'), '0,0');
    expect(moneyMillions('50000.00'), '0,1');
    expect(moneyMillions('-536100000.00'), '-536,1');
    expect(moneyMillions('-10000.00'), '0,0');
  });
}
