import 'inventory_exception.dart';

/// Name rules shared by storage writes and UI presentation (DEV-32).
abstract final class InventoryName {
  static const maxLength = 80;

  /// Sentence-style first letter only when the stored name has no uppercase
  /// yet. Leaves brands and technical spellings untouched
  /// (`iPhone`, `USB-C`, `4K`, `eBay`, `macOS`, …).
  static String display(String name) {
    if (name.isEmpty) return name;
    // Any existing uppercase letter means the graphie is intentional.
    if (name != name.toLowerCase()) return name;
    final first = name[0];
    final upper = first.toUpperCase();
    if (upper == first.toLowerCase()) return name;
    return '$upper${name.substring(1)}';
  }

  /// Trim, enforce length for new/changed names, optionally sentence-case.
  ///
  /// Historical names longer than [maxLength] may be re-saved unchanged.
  /// A different name longer than [maxLength] is rejected.
  static String normalizeForStorage(
    String name, {
    String? existingStored,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const InventoryException(InventoryErrorCode.emptyName);
    }
    final existing = existingStored?.trim();
    final unchanged = existing != null && trimmed == existing;
    if (trimmed.length > maxLength && !unchanged) {
      throw const InventoryException(InventoryErrorCode.nameTooLong);
    }
    if (unchanged) return trimmed;
    return display(trimmed);
  }
}
