import 'package:flutter/material.dart';

class ModernTabIndicator extends Decoration {
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _ModernTabPainter(this, onChanged);
  }
}

class _ModernTabPainter extends BoxPainter {
  final ModernTabIndicator decoration;

  _ModernTabPainter(this.decoration, VoidCallback? onChanged)
      : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration.size != null);
    final rect = offset & configuration.size!;

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD4AF37), Color(0xFFFFF8DC)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        rect.left,
        rect.top,
        rect.right,
        rect.bottom,
      ),
      const Radius.circular(30),
    );

    canvas.drawRRect(rrect, paint);
  }
}
