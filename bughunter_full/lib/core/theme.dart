import 'package:flutter/material.dart';

// Токены дизайна. Значения сняты с экспорта экранов из Figma-файла BugHunter.
const Color kBg = Color(0xFFF4F5FA);
const Color kPrimary = Color(0xFF5B4BFF);
const Color kPrimaryDark = Color(0xFF4F46E5);
const Color kPrimaryTint = Color(0xFFEEF0FF);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kPlaceholder = Color(0xFF94A3B8);
const Color kLine = Color(0xFFE6E8F0);
const Color kSuccess = Color(0xFF16A34A);
const Color kSuccessBg = Color(0xFFE6F6EC);
const Color kDanger = Color(0xFFDC2626);
const Color kDangerBg = Color(0xFFFEECEC);
const Color kAmber = Color(0xFFD97706);
const Color kAmberBg = Color(0xFFFFF7E6);
const Color kAmberInk = Color(0xFF92400E);
const Color kCodeBg = Color(0xFF0F172A);
const Color kCodeText = Color(0xFFE2E8F0);
const Color kCodeNumber = Color(0xFF64748B);
const Color kDisabled = Color(0xFFE7E9F0);
const Color kLockedTile = Color(0xFFF1F3F8);
const Color kBanner = Color(0xFF1F2937);
const Color kSkeleton = Color(0xFFE9ECF2);
const Color kSkeletonDark = Color(0xFFDDE1EA);

const String kFont = 'Inter';
const String kMono = 'JetBrainsMono';

/// Градиент карточки «Твой прогресс» на главной.
const LinearGradient kHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF7A6BF8), Color(0xFF4A34E6)],
);

/// Градиент заставки.
const LinearGradient kSplashGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF7A6BF8), Color(0xFF4F3BE1), Color(0xFF3B25D0)],
);

TextStyle ts(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = kInk,
  double? height,
  double? spacing,
}) {
  return TextStyle(
    fontFamily: kFont,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kPrimary, surface: kBg).copyWith(
    primary: kPrimary,
    onPrimary: Colors.white,
    primaryContainer: kPrimaryTint,
    onPrimaryContainer: kInk,
    error: kDanger,
    outline: kLine,
    surface: kBg,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: kFont,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    splashFactory: InkRipple.splashFactory,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: kPrimary,
      selectionColor: kPrimary.withAlpha(51),
      selectionHandleColor: kPrimary,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kInk,
      contentTextStyle: ts(14, weight: FontWeight.w500, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimary,
        textStyle: ts(14, weight: FontWeight.w600, color: kPrimary),
      ),
    ),
  );
}
