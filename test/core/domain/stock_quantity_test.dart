import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/domain/stock_quantity.dart';

void main() {
  test('four levels cycle 1 → ½ → ¼ → 0 → 1', () {
    expect(StockLevel.full.next, StockLevel.half);
    expect(StockLevel.half.next, StockLevel.quarter);
    expect(StockLevel.quarter.next, StockLevel.empty);
    expect(StockLevel.empty.next, StockLevel.full);
  });

  test('legacy quarters map deterministically onto four states', () {
    expect(StockLevel.fromStoredQuarters(0), StockLevel.empty);
    expect(StockLevel.fromStoredQuarters(-2), StockLevel.empty);
    expect(StockLevel.fromStoredQuarters(1), StockLevel.quarter);
    expect(StockLevel.fromStoredQuarters(2), StockLevel.half);
    expect(StockLevel.fromStoredQuarters(3), StockLevel.half);
    expect(StockLevel.fromStoredQuarters(4), StockLevel.full);
    expect(StockLevel.fromStoredQuarters(10), StockLevel.full);
  });

  test('labels are the four glyphs only', () {
    expect(StockLevel.full.label, '1');
    expect(StockLevel.half.label, '½');
    expect(StockLevel.quarter.label, '¼');
    expect(StockLevel.empty.label, '0');
  });
}
