import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  const LogoWidget({super.key, this.size = 80.0});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colors.primary, colors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withOpacity(0.25),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.cut, size: size, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'TrimCraft',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}