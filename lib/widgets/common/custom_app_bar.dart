// lib/widgets/common/custom_app_bar.dart
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final VoidCallback? onLeadingPressed;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2,
    this.onLeadingPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? (isDark ? Colors.grey[900] : Colors.white);
    final fgColor = foregroundColor ?? (isDark ? Colors.white : Colors.black87);

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: fgColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation,
      centerTitle: true,
      leading: leading ??
          (showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onLeadingPressed ?? () => Navigator.pop(context),
                )
              : null),
      actions: actions,
      iconTheme: IconThemeData(color: fgColor),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
