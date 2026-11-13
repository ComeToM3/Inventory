import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/database/inventory_database.dart';

void main() {
  test('conserve la valeur après deux fermetures et réouvertures', () async {
    final directory = await Directory.systemTemp.createTemp(
      'inventory_persistence_',
    );
    final path = '${directory.path}${Platform.pathSeparator}inventory.sqlite';
    InventoryDatabase? database;

    try {
      database = InventoryDatabase(NativeDatabase(File(path)));
      expect(await database.readVerificationValue(), isNull);
      expect(
        (await database.customSelect('PRAGMA foreign_keys').getSingle())
            .read<int>('foreign_keys'),
        1,
      );
      await database.saveVerificationValue('Première vérification');
      await database.close();
      database = null;

      database = InventoryDatabase(NativeDatabase(File(path)));
      expect(await database.readVerificationValue(), 'Première vérification');
      await database.saveVerificationValue('Deuxième vérification');
      await database.close();
      database = null;

      database = InventoryDatabase(NativeDatabase(File(path)));
      expect(await database.readVerificationValue(), 'Deuxième vérification');
    } finally {
      await database?.close();
      for (final suffix in ['', '-journal', '-wal', '-shm']) {
        final file = File('$path$suffix');
        if (await file.exists()) await file.delete();
      }
      await directory.delete();
    }
  });
}
