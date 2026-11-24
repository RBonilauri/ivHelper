import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/ui/format.dart';

void main() {
  test('formatStat tronque à une décimale avec une virgule', () {
    expect(formatStat(160.4947), '160,4');
    expect(formatStat(142.851), '142,8');
    expect(formatStat(169), '169,0');
  });

  test('formatPercent arrondit à deux décimales, 100 % en entier', () {
    expect(formatPercent(99.2753), '99,28 %');
    expect(formatPercent(100), '100 %');
    expect(formatPercent(99.99999), '100 %');
  });

  test('formatGrouped sépare les milliers par une espace insécable', () {
    expect(formatGrouped(3851770), '3 851 770');
    expect(formatGrouped(2246), '2 246');
    expect(formatGrouped(21), '21');
  });

  test('formatLevel garde la demi-décimale avec une virgule', () {
    expect(formatLevel(50), '50');
    expect(formatLevel(50.5), '50,5');
  });
}
