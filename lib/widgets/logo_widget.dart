
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  const LogoWidget({super.key, this.size = 100.0});

  @override
  Widget build(BuildContext context) {
    // Define the gold gradient
    const goldGradient = LinearGradient(
      colors: [
        Color(0xFFE4B740), // Brighter Gold
        Color(0xFFC98633), // Deeper Amber
        Color(0xFFE4B740),
        Color(0xFFFFD700), // Shinier Gold
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: [0.0, 0.4, 0.6, 1.0],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Apply the gradient to the Icon
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => goldGradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          child: Icon(Icons.cut_sharp, size: size, color: Colors.white),
        ),
        const SizedBox(height: 12),
        // Apply the gradient to the Text
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => goldGradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          child: Text(
            'TrimCraft',
            style: GoogleFonts.cinzel(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white, // This color is masked by the shader
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
