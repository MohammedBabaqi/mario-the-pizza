import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Reusable primary button with rich Italian gradient and elevation shadow.
class MarioButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Gradient? gradient;
  final bool isLoading;

  const MarioButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.gradient,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = backgroundColor == null ? (gradient ?? AppColors.primaryGradient) : null;
    final isEnabled = !isLoading && onPressed != null;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: effectiveGradient == null ? (backgroundColor ?? (isEnabled ? AppColors.primary : AppColors.grey)) : null,
        gradient: isEnabled ? effectiveGradient : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isEnabled ? onPressed : null,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
