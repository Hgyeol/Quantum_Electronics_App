import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api/client.dart';
import 'api/endpoints.dart';
import 'design/tokens.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/century_toggle.dart';
import 'widgets/theme_toggle.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  api.init(baseUrl: dotenv.env['API_URL'] ?? 'http://localhost:8000');
  runApp(const ProviderScope(child: StockApp()));
}

class StockApp extends ConsumerWidget {
  const StockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isDark = theme.mode == AppThemeMode.dark;
    final isCentury = theme.font == FontMode.century;

    final selectedTheme = isDark
        ? (isCentury ? buildDarkCenturyTheme() : buildDarkTheme())
        : (isCentury ? buildCenturyTheme() : buildLightTheme());

    // 상태바 아이콘은 테마에 맞춰 매 빌드 시 갱신.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Quantum Electronics',
      debugShowCheckedModeBanner: false,
      theme: selectedTheme,
      home: const _AuthGate(),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          // 웹 `html.century-old body { zoom: 1.3 }` 의 플러터 대응:
          // 텍스트 스케일러 1.3배로 글자·기본 패딩을 함께 키운다.
          data: mq.copyWith(
            textScaler: isCentury
                ? const TextScaler.linear(1.3)
                : const TextScaler.linear(1.0),
          ),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const Positioned(
                right: 24,
                bottom: 24,
                child: ThemeToggle(),
              ),
              const Positioned(
                right: 24,
                bottom: 88,
                child: CenturyToggle(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checking = true;
  bool _authed = false;

  @override
  void initState() {
    super.initState();
    checkAuth().then((ok) {
      if (mounted) {
        setState(() {
          _authed = ok;
          _checking = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }
    if (_authed) {
      return HomeScreen(onLogout: () => setState(() => _authed = false));
    }
    return LoginScreen(onSuccess: () => setState(() => _authed = true));
  }
}
