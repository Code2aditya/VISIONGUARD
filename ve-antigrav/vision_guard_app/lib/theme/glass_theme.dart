import 'dart:ui';
import 'package:flutter/material.dart';

class GlassTheme {
  // Base Palette
  static const Color backgroundColor = Color(0xFF0A0E17);
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color alertRed = Color(0xFFFF3366);
  static const Color warningAmber = Color(0xFFFFB300);
  static const Color successGreen = Color(0xFF00E676);

  // Glass Surface Colors (Const for compile-time safety)
  static const Color glassSurface = Color(0x0FFFFFFF); // white with 0.06 opacity
  static const Color glassSurfaceHover = Color(0x1FFFFFFF); // white with 0.12 opacity
  static const Color glassBorderColor = Color(0x2EFFFFFF); // white with 0.18 opacity
  static const Color glassCardBorder = Color(0x1FFFFFFF); // white with 0.12 opacity

  // Blur Sigma
  static const double blurSigmaX = 16.0;
  static const double blurSigmaY = 16.0;

  // Glass Container Decoration
  static BoxDecoration glassDecoration({
    double borderRadius = 24.0,
    Color? fillColor,
    Color? borderColor,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: fillColor ?? glassSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? glassBorderColor,
        width: 1.2,
      ),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
    );
  }

  // Neon Glow Decoration
  static BoxDecoration neonGlowDecoration({
    required Color color,
    double borderRadius = 20.0,
  }) {
    return BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: color.withOpacity(0.6), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // Background Ambient Gradient Blobs
  static Widget buildAmbientBackground(Widget child) {
    return Stack(
      children: [
        Container(color: backgroundColor),
        // Top Right Purple Glow
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentPurple.withOpacity(0.25),
              boxShadow: [
                BoxShadow(
                  color: accentPurple.withOpacity(0.4),
                  blurRadius: 120,
                  spreadRadius: 60,
                ),
              ],
            ),
          ),
        ),
        // Bottom Left Cyan Glow
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryCyan.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: primaryCyan.withOpacity(0.35),
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),
        // Content
        SafeArea(child: child),
      ],
    );
  }
}
