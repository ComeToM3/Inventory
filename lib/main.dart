import 'package:flutter/widgets.dart';

import 'app/inventory_app.dart';
import 'core/database/inventory_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(InventoryApp(database: InventoryDatabase()));
}
