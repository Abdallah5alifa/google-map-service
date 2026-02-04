import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  /// =======================
  /// Brand
  /// =======================
  static final Color primary = HexColor.fromHex('#FF6B00');
  static final Color secondary = HexColor.fromHex('#008000');
  static final Color purpleAccent = HexColor.fromHex('#7C3AED');

  /// =======================
  /// Backgrounds
  /// =======================
  static final Color scaffold = HexColor.fromHex('#FFFFFF');
  static final Color surface = HexColor.fromHex('#F7F7F7');
  static final Color card = HexColor.fromHex('#FFFFFF');

  /// =======================
  /// Text
  /// =======================
  static final Color textPrimary = HexColor.fromHex('#0F172A');
  static final Color textSecondary = HexColor.fromHex('#475569');
  static final Color hintTextColor = HexColor.fromHex('#94A3B8');

  /// =======================
  /// Status
  /// =======================
  static final Color success = HexColor.succesColor;
  static final Color error = HexColor.errorColor;
  static final Color warning = HexColor.warningColor;
  static final Color info = HexColor.infoColor;

  /// =======================
  /// Map / Markers
  /// =======================
  static final Color premiumMarker = purpleAccent;
  static final Color stampedMarker = HexColor.succesColor;
  static final Color regularMarker = HexColor.errorColor;

  /// =======================
  /// Borders & Dividers
  /// =======================
  static final Color border = HexColor.fromHex('#E2E8F0');
  static final Color divider = HexColor.fromHex('#CBD5E1');
}

class HexColor extends Color {
  HexColor._(super.value);

  /// Usage: HexColor.fromHex('#FF6B00')
  factory HexColor.fromHex(String hex) {
    final buffer = StringBuffer();
    hex = hex.replaceFirst('#', '');

    if (hex.length == 6) buffer.write('FF');
    buffer.write(hex);

    return HexColor._(int.parse(buffer.toString(), radix: 16));
  }

  /// Common semantic colors
  static Color get succesColor => HexColor.fromHex('#16B364');
  static Color get errorColor => HexColor.fromHex('#B60000');
  static Color get warningColor => HexColor.fromHex('#FFB020');
  static Color get infoColor => HexColor.fromHex('#017FD2');
}
