// lib/screens/family/widgets/family_invite_code.dart
import 'package:flutter/material.dart';

class FamilyInviteCode extends StatelessWidget {
  final String code;
  final Color? color;

  const FamilyInviteCode({
    Key? key,
    required this.code,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: textColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
