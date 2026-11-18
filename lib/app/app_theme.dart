import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palette alignée sur `docs/Maquette d’interface de Inventory.png`.
abstract final class InventoryColors {
  static const petroleum = Color(0xFF0B3D3A);
  static const petroleumDark = Color(0xFF062E2C);
  static const mint = Color(0xFF76ADA4);
  static const mintSoft = Color(0xFFD8EBE6);
  static const mintDeep = Color(0xFF4F8F86);
  static const surface = Color(0xFFF7F8F8);
  static const card = Color(0xFFFFFFFF);
  static const outline = Color(0xFFD5DADC);
  static const selectedRow = Color(0xFFE8ECEC);
  static const mutedText = Color(0xFF5F6B6A);
  static const chipFill = Color(0xFFE4EEF2);
}

abstract final class AppTheme {
  static ThemeData get light {
    const seed = InventoryColors.petroleum;
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      primary: InventoryColors.petroleum,
      secondary: InventoryColors.mint,
      surface: InventoryColors.surface,
      brightness: Brightness.light,
    );
    final scheme = base.copyWith(
      primaryContainer: InventoryColors.mintSoft,
      onPrimaryContainer: InventoryColors.petroleumDark,
      secondaryContainer: InventoryColors.mintSoft,
      onSecondaryContainer: InventoryColors.petroleumDark,
      outline: InventoryColors.outline,
      surfaceContainerHighest: InventoryColors.card,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: InventoryColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: InventoryColors.petroleum,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: InventoryColors.mint,
        foregroundColor: InventoryColors.petroleumDark,
        elevation: 3,
        shape: CircleBorder(),
      ),
      cardTheme: CardThemeData(
        color: InventoryColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(
          side: const BorderSide(color: InventoryColors.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: InventoryColors.chipFill,
        selectedColor: InventoryColors.mint,
        disabledColor: InventoryColors.outline,
        labelStyle: const TextStyle(
          color: InventoryColors.petroleumDark,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: StadiumBorder(
          side: BorderSide(color: InventoryColors.outline.withValues(alpha: 0.8)),
        ),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: InventoryColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: InventoryColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: InventoryColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: InventoryColors.mintDeep,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: InventoryColors.petroleum,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: InventoryColors.petroleum,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: InventoryColors.petroleum, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: InventoryColors.petroleum),
      ),
      dividerTheme: const DividerThemeData(
        color: InventoryColors.outline,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: InventoryColors.petroleum,
        textColor: InventoryColors.petroleumDark,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: InventoryColors.petroleumDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: InventoryColors.mintDeep,
      ),
    );
  }
}
