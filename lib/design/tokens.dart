import 'package:flutter/material.dart';

// ── 색상: 라이트 ──────────────────────────────────────────────────────────────
const kPrimary        = Color(0xFF3182F6);
const kPrimaryActive  = Color(0xFF2272EB);
const kTradingUp      = Color(0xFFF04452);
const kTradingDown    = Color(0xFF3182F6);

const kInk            = Color(0xFF191F28);
const kBody           = Color(0xFF333D4B);
const kBodySecondary  = Color(0xFF4E5968);
const kMuted          = Color(0xFF8B95A1);
const kMutedStrong    = Color(0xFF6B7684);

const kPageBg         = Color(0xFFF6F7F9);
const kCardBg         = Color(0xFFFFFFFF);
const kElevatedBg     = Color(0xFFF2F4F6);

const kHairline       = Color(0xFFE5E8EB);
const kBorder         = Color(0x0F022047); // rgba(2,32,71,0.06)
const kBorderMd       = Color(0x14022047); // rgba(2,32,71,0.08)
const kHover          = Color(0x0A022047); // rgba(2,32,71,0.04)
const kBgMuted        = Color(0x0D022047); // rgba(2,32,71,0.05)
const kBgSubtle       = Color(0x08022047); // rgba(2,32,71,0.03)

// ── 색상: 다크 ────────────────────────────────────────────────────────────────
const kDarkPageBg            = Color(0xFF0D1117);
const kDarkCardBg            = Color(0xFF161B22);
const kDarkElevatedBg        = Color(0xFF21262D);
const kDarkInk               = Color(0xFFE6EDF3);
const kDarkBody              = Color(0xFFC9D1D9);
const kDarkBodySecondary     = Color(0xFF8B949E);
const kDarkMuted             = Color(0xFF6E7681);
const kDarkMutedStrong       = Color(0xFF8B949E);
const kDarkHairline          = Color(0x1AF0F6FC); // rgba(240,246,252,0.10)
const kDarkBorder            = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
const kDarkBorderMd          = Color(0x21FFFFFF); // rgba(255,255,255,0.13)
const kDarkHover             = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
const kDarkBgSubtle          = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)
const kDarkBgMuted           = Color(0x12FFFFFF); // rgba(255,255,255,0.07)

// ── 타이포 ────────────────────────────────────────────────────────────────────
const kFontMono = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

TextStyle monoStyle({
  double size = 15,
  FontWeight weight = FontWeight.w600,
  Color color = kInk,
}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

// ── 사이즈 ────────────────────────────────────────────────────────────────────
const kRowPaddingH    = 20.0;
const kRowPaddingV    = 12.0;
const kHeaderPaddingH = 20.0;
const kSectionRadius  = 0.0;

// ── ThemeExtension: AppPalette ────────────────────────────────────────────────
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color ink;
  final Color body;
  final Color bodySecondary;
  final Color muted;
  final Color mutedStrong;
  final Color pageBg;
  final Color cardBg;
  final Color elevatedBg;
  final Color hairline;
  final Color border;
  final Color borderMd;
  final Color hover;
  final Color bgSubtle;
  final Color bgMuted;
  final Color tradingUp;
  final Color tradingDown;
  final Color primary;
  final Color primaryActive;

  const AppPalette({
    required this.ink,
    required this.body,
    required this.bodySecondary,
    required this.muted,
    required this.mutedStrong,
    required this.pageBg,
    required this.cardBg,
    required this.elevatedBg,
    required this.hairline,
    required this.border,
    required this.borderMd,
    required this.hover,
    required this.bgSubtle,
    required this.bgMuted,
    required this.tradingUp,
    required this.tradingDown,
    required this.primary,
    required this.primaryActive,
  });

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith({
    Color? ink,
    Color? body,
    Color? bodySecondary,
    Color? muted,
    Color? mutedStrong,
    Color? pageBg,
    Color? cardBg,
    Color? elevatedBg,
    Color? hairline,
    Color? border,
    Color? borderMd,
    Color? hover,
    Color? bgSubtle,
    Color? bgMuted,
    Color? tradingUp,
    Color? tradingDown,
    Color? primary,
    Color? primaryActive,
  }) =>
      AppPalette(
        ink: ink ?? this.ink,
        body: body ?? this.body,
        bodySecondary: bodySecondary ?? this.bodySecondary,
        muted: muted ?? this.muted,
        mutedStrong: mutedStrong ?? this.mutedStrong,
        pageBg: pageBg ?? this.pageBg,
        cardBg: cardBg ?? this.cardBg,
        elevatedBg: elevatedBg ?? this.elevatedBg,
        hairline: hairline ?? this.hairline,
        border: border ?? this.border,
        borderMd: borderMd ?? this.borderMd,
        hover: hover ?? this.hover,
        bgSubtle: bgSubtle ?? this.bgSubtle,
        bgMuted: bgMuted ?? this.bgMuted,
        tradingUp: tradingUp ?? this.tradingUp,
        tradingDown: tradingDown ?? this.tradingDown,
        primary: primary ?? this.primary,
        primaryActive: primaryActive ?? this.primaryActive,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      ink: Color.lerp(ink, other.ink, t)!,
      body: Color.lerp(body, other.body, t)!,
      bodySecondary: Color.lerp(bodySecondary, other.bodySecondary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedStrong: Color.lerp(mutedStrong, other.mutedStrong, t)!,
      pageBg: Color.lerp(pageBg, other.pageBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      elevatedBg: Color.lerp(elevatedBg, other.elevatedBg, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderMd: Color.lerp(borderMd, other.borderMd, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      bgSubtle: Color.lerp(bgSubtle, other.bgSubtle, t)!,
      bgMuted: Color.lerp(bgMuted, other.bgMuted, t)!,
      tradingUp: Color.lerp(tradingUp, other.tradingUp, t)!,
      tradingDown: Color.lerp(tradingDown, other.tradingDown, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryActive: Color.lerp(primaryActive, other.primaryActive, t)!,
    );
  }
}

const _lightPalette = AppPalette(
  ink: kInk,
  body: kBody,
  bodySecondary: kBodySecondary,
  muted: kMuted,
  mutedStrong: kMutedStrong,
  pageBg: kPageBg,
  cardBg: kCardBg,
  elevatedBg: kElevatedBg,
  hairline: kHairline,
  border: kBorder,
  borderMd: kBorderMd,
  hover: kHover,
  bgSubtle: kBgSubtle,
  bgMuted: kBgMuted,
  tradingUp: kTradingUp,
  tradingDown: kTradingDown,
  primary: kPrimary,
  primaryActive: kPrimaryActive,
);

const _darkPalette = AppPalette(
  ink: kDarkInk,
  body: kDarkBody,
  bodySecondary: kDarkBodySecondary,
  muted: kDarkMuted,
  mutedStrong: kDarkMutedStrong,
  pageBg: kDarkPageBg,
  cardBg: kDarkCardBg,
  elevatedBg: kDarkElevatedBg,
  hairline: kDarkHairline,
  border: kDarkBorder,
  borderMd: kDarkBorderMd,
  hover: kDarkHover,
  bgSubtle: kDarkBgSubtle,
  bgMuted: kDarkBgMuted,
  tradingUp: kTradingUp,
  tradingDown: kTradingDown,
  primary: kPrimary,
  primaryActive: kPrimaryActive,
);

// ── ThemeData ─────────────────────────────────────────────────────────────────
ThemeData _buildTheme({
  required Brightness brightness,
  required AppPalette palette,
}) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.pageBg,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: Colors.white,
      secondary: palette.primary,
      onSecondary: Colors.white,
      error: palette.tradingUp,
      onError: Colors.white,
      surface: palette.cardBg,
      onSurface: palette.ink,
      surfaceContainerHighest: palette.elevatedBg,
      onSurfaceVariant: palette.body,
      outline: palette.hairline,
      outlineVariant: palette.border,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.cardBg,
      foregroundColor: palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ),
      iconTheme: IconThemeData(color: palette.ink),
      surfaceTintColor: Colors.transparent,
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: palette.ink,
      labelColor: palette.ink,
      unselectedLabelColor: palette.mutedStrong,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: palette.border,
    ),
    dividerTheme: DividerThemeData(
      color: palette.border,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: palette.cardBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: palette.cardBg,
      selectedItemColor: palette.primary,
      unselectedItemColor: palette.muted,
      selectedLabelStyle:
          const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.cardBg,
      indicatorColor: palette.primary.withAlpha(25),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color:
              s.contains(WidgetState.selected) ? palette.primary : palette.muted,
          size: 22,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 10,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
          color:
              s.contains(WidgetState.selected) ? palette.primary : palette.muted,
        ),
      ),
      height: 60,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(0, 48),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: palette.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: palette.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: palette.primary, width: 2),
      ),
      labelStyle: TextStyle(color: palette.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    iconTheme: IconThemeData(color: palette.ink),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: palette.ink),
      bodyMedium: TextStyle(color: palette.body),
      bodySmall: TextStyle(color: palette.bodySecondary),
      titleLarge: TextStyle(color: palette.ink, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: palette.ink, fontWeight: FontWeight.w700),
      titleSmall: TextStyle(color: palette.ink, fontWeight: FontWeight.w700),
      labelLarge: TextStyle(color: palette.ink),
      labelMedium: TextStyle(color: palette.body),
      labelSmall: TextStyle(color: palette.muted),
    ),
    extensions: <ThemeExtension<dynamic>>[palette],
  );
}

ThemeData buildLightTheme() =>
    _buildTheme(brightness: Brightness.light, palette: _lightPalette);

ThemeData buildDarkTheme() =>
    _buildTheme(brightness: Brightness.dark, palette: _darkPalette);
