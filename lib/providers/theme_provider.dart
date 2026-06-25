import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 라이트 ↔ 다크 모드.
enum AppThemeMode { light, dark }

class ThemeState {
  final AppThemeMode mode;

  const ThemeState({this.mode = AppThemeMode.light});

  ThemeState copyWith({AppThemeMode? mode}) =>
      ThemeState(mode: mode ?? this.mode);
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    // 비동기 로드 — 첫 프레임은 기본값으로 그려진 뒤 prefs가 들어오면 갱신됨.
    _load();
  }

  // 웹 localStorage 키와 동일 — 동일한 키로 영속화해 같은 사용자 멘탈모델 유지.
  static const _kThemeKey = 'theme';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_kThemeKey);
    state = ThemeState(
      mode: themeStr == 'dark' ? AppThemeMode.dark : AppThemeMode.light,
    );
  }

  Future<void> toggleTheme() async {
    final next = state.mode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    await setMode(next);
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kThemeKey,
      mode == AppThemeMode.dark ? 'dark' : 'light',
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);
