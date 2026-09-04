import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Displays a sleek, modern floating toast that auto-dismisses after 2 seconds.
void showMarioSnackBar(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_rounded,
  Color iconColor = AppColors.goldenCheese,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1E2022),
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
    ),
  );
}
