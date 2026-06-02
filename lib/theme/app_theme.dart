import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Aksen / tint (sedikit ditinggikan agar 'glow' di latar gelap)
  static const lavender = Color(0xFFB6A6FF);
  static const peach = Color(0xFFFFC59E);
  static const mint = Color(0xFF8FE0C6);
  static const sky = Color(0xFF93C2FF);
  static const pink = Color(0xFFFFA6C9);
  static const cream = Color(0xFFFFF7E6);

  // Brand (ungu) — dipakai untuk tombol, pill, state terpilih
  static const primary = Color(0xFF8B7CF6);
  static const primaryDeep = Color(0xFF6E5CE6);
  static const onPrimary = Color(0xFFFFFFFF);

  // Netral (gelap)
  static const surface = Color(0xFF0E1016); // latar dasar app
  static const card = Color(0xFF171A24); // permukaan kartu solid (acuan)
  static const ink = Color(0xFFEDEBF7); // teks utama (terang)
  static const inkSoft = Color(0xFF9C99B4); // teks sekunder

  // Permukaan kaca di atas latar gelap
  static final glassFill = Colors.white.withValues(alpha: 0.055);
  static final glassStroke = Colors.white.withValues(alpha: 0.10);
  static final chipFill = Colors.white.withValues(alpha: 0.10);

  // Gradient latar (gelap keunguan)
  static const gradientStart = Color(0xFF1B1530);
  static const gradientMid = Color(0xFF141826);
  static const gradientEnd = Color(0xFF0E1016);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.lavender,
        surface: AppColors.surface,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glassFill,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelStyle: textTheme.bodyMedium,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
