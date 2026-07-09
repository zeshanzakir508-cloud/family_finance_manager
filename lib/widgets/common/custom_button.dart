// lib/widgets/common/custom_button.dart
import 'package:flutter/material.dart';

enum ButtonType {
  primary,
  outline,
  danger,
  text,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isFullWidth;

  const CustomButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isFullWidth = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color getBackgroundColor() {
      switch (type) {
        case ButtonType.primary:
          return theme.primaryColor;
        case ButtonType.outline:
          return Colors.transparent;
        case ButtonType.danger:
          return Colors.red;
        case ButtonType.text:
          return Colors.transparent;
      }
    }

    Color getTextColor() {
      switch (type) {
        case ButtonType.primary:
          return Colors.white;
        case ButtonType.outline:
          return theme.primaryColor;
        case ButtonType.danger:
          return Colors.white;
        case ButtonType.text:
          return theme.primaryColor;
      }
    }

    Color getBorderColor() {
      switch (type) {
        case ButtonType.primary:
          return theme.primaryColor;
        case ButtonType.outline:
          return theme.primaryColor;
        case ButtonType.danger:
          return Colors.red;
        case ButtonType.text:
          return Colors.transparent;
      }
    }

    EdgeInsets getPadding() {
      switch (size) {
        case ButtonSize.small:
          return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        case ButtonSize.medium:
          return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
        case ButtonSize.large:
          return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
      }
    }

    double getFontSize() {
      switch (size) {
        case ButtonSize.small:
          return 12;
        case ButtonSize.medium:
          return 14;
        case ButtonSize.large:
          return 16;
      }
    }

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: getBackgroundColor(),
        foregroundColor: getTextColor(),
        padding: getPadding(),
        minimumSize: isFullWidth ? const Size(double.infinity, 0) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: getBorderColor(),
            width: type == ButtonType.outline ? 1.5 : 0,
          ),
        ),
        elevation: type == ButtonType.primary ? 2 : 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else ...[
            if (icon != null) ...[
              Icon(icon, size: getFontSize() + 4),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: getFontSize(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    if (type == ButtonType.text) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: getTextColor(),
          padding: getPadding(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: getFontSize() + 4),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: getFontSize(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return button;
  }
}
