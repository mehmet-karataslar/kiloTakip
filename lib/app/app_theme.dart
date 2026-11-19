import 'package:flutter/material.dart';

import '../domain/measurements.dart';
import '../l10n/app_localizations.dart';

enum AppColorPalette {
  ocean(
    'Okyanus & Altın Sarısı',
    'Mavi & Sıcak Kehribar Uyumu',
    Color(0xFF166FE5),
    Color(0xFFD97706),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
  ),
  emerald(
    'Zümrüt & Güneş Sarısı',
    'Zümrüt Yeşili & Canlı Altın Uyumu',
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF10B981),
    Color(0xFFFBBF24),
  ),
  navy(
    'Koyu Lacivert & Nane Yeşili',
    'Asil Lacivert & Ferah Yeşil Uyumu',
    Color(0xFF1E3A8A),
    Color(0xFF0D9488),
    Color(0xFF60A5FA),
    Color(0xFF2DD4BF),
  ),
  forest(
    'Orman Yeşili & Kehribar',
    'Doğal Yeşil & Sıcak Sarı Uyumu',
    Color(0xFF15803D),
    Color(0xFFD97706),
    Color(0xFF22C55E),
    Color(0xFFFBBF24),
  ),
  crimson(
    'Ateş Kırmızısı & Lacivert',
    'Dinamik Kırmızı & Koyu Mavi Uyumu',
    Color(0xFFDC2626),
    Color(0xFF1E3A8A),
    Color(0xFFEF4444),
    Color(0xFF60A5FA),
  ),
  amber(
    'Kehribar Sarısı & Gece Mavisi',
    'Sıcak Sarı & Derin Mavi Uyumu',
    Color(0xFFD97706),
    Color(0xFF1E3A8A),
    Color(0xFFF59E0B),
    Color(0xFF38BDF8),
  ),
  coral(
    'Mercan & Turkuaz',
    'Sıcak Mercan Kırmızısı & Deniz Mavisi Uyumu',
    Color(0xFFE11D48),
    Color(0xFF0891B2),
    Color(0xFFFB7185),
    Color(0xFF22D3EE),
  ),
  anthracite(
    'Antrasit & Çelik Mavi',
    'Koyu Grafit & Canlı Mavi Uyumu',
    Color(0xFF334155),
    Color(0xFF0284C7),
    Color(0xFF94A3B8),
    Color(0xFF38BDF8),
  );

  const AppColorPalette(
    this._rawLabel,
    this._rawDesc,
    this.lightPrimary,
    this.lightSecondary,
    this.darkPrimary,
    this.darkSecondary,
  );

  final String _rawLabel;
  final String _rawDesc;
  String get label => trText(_rawLabel);
  String get description => trText(_rawDesc);
  final Color lightPrimary;
  final Color lightSecondary;
  final Color darkPrimary;
  final Color darkSecondary;
}

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.cardSurface,
    required this.cardBorder,
    required this.heading,
    required this.subtitle,
    required this.primaryBlue,
    required this.primarySoft,
    required this.morningSurface,
    required this.morningBorder,
    required this.morningAccent,
    required this.eveningSurface,
    required this.eveningBorder,
    required this.eveningAccent,
    required this.greenSurface,
    required this.greenBorder,
    required this.greenText,
    required this.orangeSurface,
    required this.orangeBorder,
    required this.orangeText,
    required this.chipUnselected,
    required this.shadowColor,
  });

  final Color background;
  final Color cardSurface;
  final Color cardBorder;
  final Color heading;
  final Color subtitle;
  final Color primaryBlue;
  final Color primarySoft;
  final Color morningSurface;
  final Color morningBorder;
  final Color morningAccent;
  final Color eveningSurface;
  final Color eveningBorder;
  final Color eveningAccent;
  final Color greenSurface;
  final Color greenBorder;
  final Color greenText;
  final Color orangeSurface;
  final Color orangeBorder;
  final Color orangeText;
  final Color chipUnselected;
  final Color shadowColor;

  static const light = AppColors(
    background: Color(0xFFF4F7FC),
    cardSurface: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE3ECF8),
    heading: Color(0xFF0E2547),
    subtitle: Color(0xFF64748B),
    primaryBlue: Color(0xFF166FE5),
    primarySoft: Color(0xFFE7F1FF),
    morningSurface: Color(0xFFEDF5FF),
    morningBorder: Color(0xFFD5E6FF),
    morningAccent: Color(0xFF166FE5),
    eveningSurface: Color(0xFFFFF7ED),
    eveningBorder: Color(0xFFFED7AA),
    eveningAccent: Color(0xFFD97706),
    greenSurface: Color(0xFFE9F8EF),
    greenBorder: Color(0xFFCCEED9),
    greenText: Color(0xFF15803D),
    orangeSurface: Color(0xFFFFF3E6),
    orangeBorder: Color(0xFFFDE0C0),
    orangeText: Color(0xFFD97706),
    chipUnselected: Color(0xFFE9F0FA),
    shadowColor: Color(0x0C0E2547),
  );

  static const dark = AppColors(
    background: Color(0xFF0B1320),
    cardSurface: Color(0xFF131F33),
    cardBorder: Color(0xFF223452),
    heading: Color(0xFFF1F5F9),
    subtitle: Color(0xFF94A3B8),
    primaryBlue: Color(0xFF3B82F6),
    primarySoft: Color(0xFF1B3358),
    morningSurface: Color(0xFF162844),
    morningBorder: Color(0xFF254470),
    morningAccent: Color(0xFF60A5FA),
    eveningSurface: Color(0xFF2D1E0C),
    eveningBorder: Color(0xFF5A3A16),
    eveningAccent: Color(0xFFF59E0B),
    greenSurface: Color(0xFF112D21),
    greenBorder: Color(0xFF1D4D38),
    greenText: Color(0xFF4ADE80),
    orangeSurface: Color(0xFF362015),
    orangeBorder: Color(0xFF5C3522),
    orangeText: Color(0xFFFB923C),
    chipUnselected: Color(0xFF1A2942),
    shadowColor: Color(0x33000000),
  );

  static AppColors forPalette(
    AppColorPalette palette,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    if (palette == AppColorPalette.ocean) {
      return isDark ? dark : light;
    }
    final primary = isDark ? palette.darkPrimary : palette.lightPrimary;
    final secondary = isDark ? palette.darkSecondary : palette.lightSecondary;
    final base = isDark ? dark : light;

    Color tint(Color c, double amount) => Color.lerp(
      isDark ? const Color(0xFF131F33) : Colors.white,
      c,
      amount,
    )!;

    return base.copyWith(
      background: isDark
          ? Color.lerp(const Color(0xFF0B1320), primary, 0.06)
          : Color.lerp(const Color(0xFFF4F7FC), primary, 0.04),
      cardBorder: isDark
          ? Color.lerp(const Color(0xFF223452), primary, 0.18)
          : Color.lerp(const Color(0xFFE3ECF8), primary, 0.16),
      primaryBlue: primary,
      primarySoft: tint(primary, isDark ? 0.24 : 0.12),
      morningSurface: tint(primary, isDark ? 0.20 : 0.09),
      morningBorder: tint(primary, isDark ? 0.38 : 0.22),
      morningAccent: primary,
      eveningSurface: tint(secondary, isDark ? 0.20 : 0.09),
      eveningBorder: tint(secondary, isDark ? 0.38 : 0.22),
      eveningAccent: secondary,
      chipUnselected: tint(primary, isDark ? 0.14 : 0.07),
    );
  }

  Color slotAccent(Slot slot) =>
      slot == Slot.morning ? morningAccent : eveningAccent;
  Color slotSurface(Slot slot) =>
      slot == Slot.morning ? morningSurface : eveningSurface;
  Color slotBorder(Slot slot) =>
      slot == Slot.morning ? morningBorder : eveningBorder;

  @override
  AppColors copyWith({
    Color? background,
    Color? cardSurface,
    Color? cardBorder,
    Color? heading,
    Color? subtitle,
    Color? primaryBlue,
    Color? primarySoft,
    Color? morningSurface,
    Color? morningBorder,
    Color? morningAccent,
    Color? eveningSurface,
    Color? eveningBorder,
    Color? eveningAccent,
    Color? greenSurface,
    Color? greenBorder,
    Color? greenText,
    Color? orangeSurface,
    Color? orangeBorder,
    Color? orangeText,
    Color? chipUnselected,
    Color? shadowColor,
  }) => AppColors(
    background: background ?? this.background,
    cardSurface: cardSurface ?? this.cardSurface,
    cardBorder: cardBorder ?? this.cardBorder,
    heading: heading ?? this.heading,
    subtitle: subtitle ?? this.subtitle,
    primaryBlue: primaryBlue ?? this.primaryBlue,
    primarySoft: primarySoft ?? this.primarySoft,
    morningSurface: morningSurface ?? this.morningSurface,
    morningBorder: morningBorder ?? this.morningBorder,
    morningAccent: morningAccent ?? this.morningAccent,
    eveningSurface: eveningSurface ?? this.eveningSurface,
    eveningBorder: eveningBorder ?? this.eveningBorder,
    eveningAccent: eveningAccent ?? this.eveningAccent,
    greenSurface: greenSurface ?? this.greenSurface,
    greenBorder: greenBorder ?? this.greenBorder,
    greenText: greenText ?? this.greenText,
    orangeSurface: orangeSurface ?? this.orangeSurface,
    orangeBorder: orangeBorder ?? this.orangeBorder,
    orangeText: orangeText ?? this.orangeText,
    chipUnselected: chipUnselected ?? this.chipUnselected,
    shadowColor: shadowColor ?? this.shadowColor,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      heading: Color.lerp(heading, other.heading, t)!,
      subtitle: Color.lerp(subtitle, other.subtitle, t)!,
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      morningSurface: Color.lerp(morningSurface, other.morningSurface, t)!,
      morningBorder: Color.lerp(morningBorder, other.morningBorder, t)!,
      morningAccent: Color.lerp(morningAccent, other.morningAccent, t)!,
      eveningSurface: Color.lerp(eveningSurface, other.eveningSurface, t)!,
      eveningBorder: Color.lerp(eveningBorder, other.eveningBorder, t)!,
      eveningAccent: Color.lerp(eveningAccent, other.eveningAccent, t)!,
      greenSurface: Color.lerp(greenSurface, other.greenSurface, t)!,
      greenBorder: Color.lerp(greenBorder, other.greenBorder, t)!,
      greenText: Color.lerp(greenText, other.greenText, t)!,
      orangeSurface: Color.lerp(orangeSurface, other.orangeSurface, t)!,
      orangeBorder: Color.lerp(orangeBorder, other.orangeBorder, t)!,
      orangeText: Color.lerp(orangeText, other.orangeText, t)!,
      chipUnselected: Color.lerp(chipUnselected, other.chipUnselected, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}

class AppTheme {
  static ThemeData build(
    Brightness brightness, [
    AppColorPalette colorPalette = AppColorPalette.ocean,
  ]) {
    final isDark = brightness == Brightness.dark;
    final palette = AppColors.forPalette(colorPalette, brightness);
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primaryBlue,
      brightness: brightness,
      primary: palette.primaryBlue,
      surface: palette.cardSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.cardSurface,
        foregroundColor: palette.heading,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: palette.heading,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: palette.subtitle),
      ),
      cardTheme: CardThemeData(
        color: palette.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: isDark ? const Color(0xFF192841) : const Color(0xFFF8FAFE),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.primaryBlue, width: 1.8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

