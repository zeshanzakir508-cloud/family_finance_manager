import 'package:flutter/material.dart';
import '../services/remote_config_service.dart';

class CustomMessageWidget extends StatefulWidget {
  final Widget child;

  const CustomMessageWidget({super.key, required this.child});

  @override
  State<CustomMessageWidget> createState() => _CustomMessageWidgetState();
}

class _CustomMessageWidgetState extends State<CustomMessageWidget> {
  bool _messageShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMessageIfNeeded();
    });
  }

  void _showMessageIfNeeded() {
    if (_messageShown) return;

    final showMessage = RemoteConfigService.showMessage;
    final isValid = RemoteConfigService.isMessageValid;

    if (showMessage && isValid) {
      _messageShown = true;
      _showMessageDialog();
    }
  }

  void _showMessageDialog() {
    final title = RemoteConfigService.messageTitle;
    final body = RemoteConfigService.messageBody;
    final icon = RemoteConfigService.messageIcon.isEmpty
        ? RemoteConfigService.getMessageIconByType(RemoteConfigService.messageType)
        : RemoteConfigService.messageIcon;
    final type = RemoteConfigService.messageType;
    final color = RemoteConfigService.getMessageColor(type);
    final buttonText = RemoteConfigService.messageButtonText;

    if (title.isEmpty && body.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              buttonText,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
