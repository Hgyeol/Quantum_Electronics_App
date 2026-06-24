import 'package:flutter/material.dart';
import '../api/endpoints.dart';
import '../design/tokens.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  const LoginScreen({super.key, required this.onSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  Future<void> _login() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text;
    if (u.isEmpty || p.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      await login(u, p);
      widget.onSuccess();
    } catch (_) {
      setState(() { _error = '아이디 또는 비밀번호를 확인해주세요.'; _loading = false; });
    }
  }

  @override
  void dispose() { _userCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 72),
              // 로고 영역
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.show_chart, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 20),
              const Text('로그인',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: kInk)),
              const SizedBox(height: 4),
              Text('Quantum Electronics',
                  style: TextStyle(fontSize: 13, color: kMuted)),
              const SizedBox(height: 40),
              // 입력 필드
              _Field(
                controller: _userCtrl,
                label: '아이디',
                action: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _passCtrl,
                label: '비밀번호',
                obscure: _obscure,
                action: TextInputAction.done,
                onSubmitted: (_) => _login(),
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: kMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: const TextStyle(color: kTradingDown, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              // 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: kHairline,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('로그인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputAction? action;
  final void Function(String)? onSubmitted;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.action,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 15, color: kInk),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14, color: kMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kHairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kHairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: suffix,
        filled: true,
        fillColor: kCardBg,
      ),
    );
  }
}
