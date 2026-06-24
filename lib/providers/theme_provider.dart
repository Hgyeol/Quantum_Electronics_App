import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 라이트 ↔ 다크 모드.
enum AppThemeMode { light, dark }

/// 일반 글꼴 ↔ 50대 친화(큰 글씨) 모드.
enum FontMode { normal, century }

class ThemeState {
  final AppThemeMode mode;
  final FontMode font;

  const ThemeState({
    this.mode = AppThemeMode.light,
    this.font = FontMode.normal,
  });

  ThemeState copyWith({AppThemeMode? mode, FontMode? font}) => ThemeState(
        mode: mode ?? this.mode,
        font: font ?? this.font,
      );
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    // 비동기 로드 — 첫 프레임은 기본값으로 그려진 뒤 prefs가 들어오면 갱신됨.
    _load();
  }

  // 웹 localStorage 키와 동일 — 동일한 키로 영속화해 같은 사용자 멘탈모델 유지.
  static const _kThemeKey = 'theme';
  static const _kCenturyKey = 'century';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_kThemeKey);
    final centuryStr = prefs.getString(_kCenturyKey);
    state = ThemeState(
      mode: themeStr == 'dark' ? AppThemeMode.dark : AppThemeMode.light,
      font: centuryStr == 'old' ? FontMode.century : FontMode.normal,
    );
  }

  Future<void> toggleTheme() async {
    final next = state.mode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    state = state.copyWith(mode: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kThemeKey,
      next == AppThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> toggleCentury() async {
    final next =
        state.font == FontMode.century ? FontMode.normal : FontMode.century;
    state = state.copyWith(font: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCenturyKey,
      next == FontMode.century ? 'old' : 'new',
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);
