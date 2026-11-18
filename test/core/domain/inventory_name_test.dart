import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/domain/inventory_exception.dart';
import 'package:inventory/core/domain/inventory_name.dart';

void main() {
  group('InventoryName.display', () {
    test('capitalise la première lettre minuscule seulement', () {
      expect(InventoryName.display('chambre'), 'Chambre');
      expect(InventoryName.display('bureau assis debout'), 'Bureau assis debout');
      expect(InventoryName.display('guitar godin'), 'Guitar godin');
    });

    test('préserve marques, sigles et graphies techniques', () {
      expect(InventoryName.display('iPhone'), 'iPhone');
      expect(InventoryName.display('eBay'), 'eBay');
      expect(InventoryName.display('macOS'), 'macOS');
      expect(InventoryName.display('USB-C'), 'USB-C');
      expect(InventoryName.display('4K'), '4K');
      expect(InventoryName.display('Chambre'), 'Chambre');
    });
  });

  group('InventoryName.normalizeForStorage', () {
    test('trim et capitalise à la création', () {
      expect(
        InventoryName.normalizeForStorage('  clavier  '),
        'Clavier',
      );
    });

    test('conserve un nom historique inchangé même s’il dépasse 80', () {
      final long = 'x' * 90;
      expect(
        InventoryName.normalizeForStorage(long, existingStored: long),
        long,
      );
    });

    test('refuse un nouveau nom trop long', () {
      expect(
        () => InventoryName.normalizeForStorage('y' * 81),
        throwsA(
          isA<InventoryException>().having(
            (e) => e.code,
            'code',
            InventoryErrorCode.nameTooLong,
          ),
        ),
      );
    });

    test('refuse un nom vide', () {
      expect(
        () => InventoryName.normalizeForStorage('   '),
        throwsA(
          isA<InventoryException>().having(
            (e) => e.code,
            'code',
            InventoryErrorCode.emptyName,
          ),
        ),
      );
    });
  });
}
