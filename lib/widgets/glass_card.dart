// lib/widgets/glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurStrength;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.blurStrength = 10.0,
    this.opacity = 0.2,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color glassColor = color ?? (isDark ? Colors.white : Colors.white);
    final Color borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.3);

    return Container(
      width: width,
      height: height,
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: glassColor.withOpacity(opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: blurStrength > 0
              ? ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              color: Colors.transparent,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
