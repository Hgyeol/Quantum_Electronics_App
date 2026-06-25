import 'package:flutter/material.dart';

const List<Color> _palette = [
  Color(0xFF3182F6),
  Color(0xFF03B26C),
  Color(0xFFF04452),
  Color(0xFFF5A623),
  Color(0xFF9B59B6),
  Color(0xFF18A5A5),
  Color(0xFF2ECC71),
  Color(0xFFE67E22),
  Color(0xFF1ABC9C),
  Color(0xFF8E44AD),
];

class StockLogo extends StatelessWidget {
  final String code;
  final String? name;
  final double size;
  final bool circle;

  const StockLogo({
    super.key,
    required this.code,
    this.name,
    this.size = 40,
    this.circle = false,
  });

  Color _baseColor() {
    int hash = 0;
    for (final c in code.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return _palette[hash % _palette.length];
  }

  Widget _avatar({double? sz}) {
    final s = sz ?? size;
    final c = _baseColor();
    final src = name ?? code;
    final initial = src.isNotEmpty ? src[0] : '?';
    final radius = circle ? s / 2 : 16.0;

    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: s * 0.38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = circle ? size / 2 : 16.0;
    final assetPath = 'assets/stocks/$code.png';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => _avatar(),
      ),
    );
  }
}
