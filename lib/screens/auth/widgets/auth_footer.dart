// lib/screens/auth/widgets/auth_footer.dart
import 'package:flutter/material.dart';

class AuthFooter extends StatelessWidget {
  final String text;
  final String buttonText;
  final VoidCallback onTap;

  const AuthFooter({
    Key? key,
    required this.text,
    required this.buttonText,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            buttonText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
