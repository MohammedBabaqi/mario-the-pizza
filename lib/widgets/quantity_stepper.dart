import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Quantity stepper for cart items with delete support at 1.
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final VoidCallback? onDelete;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: quantity == 1 ? Icons.delete_outline_rounded : Icons.remove,
            color: quantity == 1 ? AppColors.primary : null,
            onTap: () {
              if (quantity > 1) {
                onChanged(quantity - 1);
              } else {
                if (onDelete != null) {
                  onDelete!();
                } else {
                  onChanged(0);
                }
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.text,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _StepButton({required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: color ?? (onTap != null ? AppColors.primary : context.textSecondary),
        ),
      ),
    );
  }
}
