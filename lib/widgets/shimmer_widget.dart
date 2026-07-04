// lib/widgets/shimmer_widget.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  const ShimmerWidget.circular({
    super.key,
    this.width = 48,
    this.height = 48,
    this.borderRadius,
    this.margin,
  });

  const ShimmerWidget.rectangular({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final Color highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
