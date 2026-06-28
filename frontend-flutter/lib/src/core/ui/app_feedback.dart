import 'package:flutter/material.dart';

class AppFeedback {
  const AppFeedback._();

  static void showSuccess(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    _showSnackBar(
      context,
      title: title,
      message: message,
      icon: Icons.check_circle_outline,
      color: const Color(0xFF0F766E),
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    _showSnackBar(
      context,
      title: title,
      message: message,
      icon: Icons.info_outline,
      color: const Color(0xFF2563EB),
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    _showSnackBar(
      context,
      title: title,
      message: message,
      icon: Icons.error_outline,
      color: Theme.of(context).colorScheme.error,
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    if (!context.mounted) {
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          icon: Icon(Icons.error_outline, color: colorScheme.error),
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String title,
    required String? message,
    required IconData icon,
    required Color color,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 6,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF16201D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((message ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      message!.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5F6F69),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
