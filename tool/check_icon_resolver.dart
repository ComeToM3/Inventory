import 'package:inventory/core/domain/inventory_models.dart';
import 'package:inventory/core/icons/inventory_icon_catalog.dart';
import 'package:inventory/core/icons/inventory_icon_dictionary.dart';
import 'package:inventory/core/icons/inventory_icon_resolver.dart';

void main() {
  final samples = <(String, NodeType, String?)>[
    ('Salon', NodeType.location, 'living'),
    ('Chambres', NodeType.location, 'bedroom'),
    ('Cuisine', NodeType.location, 'kitchen'),
    ('Salle de bain', NodeType.location, 'bathroom'),
    ('Garage', NodeType.location, 'garage'),
    ('Chalet', NodeType.location, 'cottage'),
    ('Ordinateur portable', NodeType.item, 'laptop'),
    ('Écran Dell', NodeType.item, 'monitor'),
    ('Clavier mécanique', NodeType.item, 'keyboard'),
    ('Souris sans fil', NodeType.item, 'mouse'),
    ('Imprimante laser', NodeType.item, 'print'),
    ('Câble HDMI', NodeType.item, 'cable'),
    ('Routeur Wi-Fi', NodeType.item, 'router'),
    ('Disque SSD', NodeType.item, 'hard_drive'),
    ('Valise rouge', NodeType.itemContainer, 'luggage'),
    ('Boîte à outils', NodeType.itemContainer, 'handyman'),
    ('Armoire', NodeType.itemContainer, 'inventory_2'),
    ('Réfrigérateur', NodeType.item, 'kitchen'),
    ('Micro-ondes', NodeType.item, 'microwave'),
    ('Aspirateur', NodeType.item, 'vacuum'),
    ('Chaussures de course', NodeType.item, 'shoes'),
    ('Médicaments', NodeType.item, 'medication'),
    ('Vélo électrique', NodeType.item, 'pedal_bike'),
    ('Livre de recettes', NodeType.item, 'menu_book'),
    ('Guitare', NodeType.item, 'music_note'),
    ('Croquettes chat', NodeType.item, 'pets'),
    ('Bureau', NodeType.location, 'business'),
    ('Bureau meuble', NodeType.item, 'desk'),
    ('xyzzy-inconnu-42', NodeType.item, null),
    ('xyzzy-inconnu-42', NodeType.location, null),
  ];

  var ok = 0;
  for (final (name, type, expected) in samples) {
    final key = InventoryIconResolver.resolveKey(name: name, type: type);
    final pass = expected == null
        ? key == null
        : key == expected;
    if (!pass) {
      print('FAIL "$name" ($type) -> $key (expected $expected)');
    } else {
      ok++;
    }
  }
  print(
    'resolver samples: $ok/${samples.length} ; '
    'terms=${InventoryIconDictionary.termCount} ; '
    'catalog=${InventoryIconCatalog.selectableKeys.length}',
  );
}
