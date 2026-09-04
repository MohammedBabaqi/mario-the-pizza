import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pizza_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';

/// Pizza Card widget with internet image.
/// Requirement: Card.
class PizzaCard extends StatelessWidget {
  final PizzaModel pizza;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const PizzaCard({
    super.key,
    required this.pizza,
    required this.onTap,
    required this.onQuickAdd,
    this.width = 210,
    this.margin = const EdgeInsets.only(right: 16),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.border),
          boxShadow: context.isDark
              ? []
              : [
                  BoxShadow(
                    color: AppColors.dark.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pizza Image with Rating Badge
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Center(
                    child: Hero(
                      tag: 'pizza_hero_${pizza.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: pizza.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: context.surfaceHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('🍕', style: TextStyle(fontSize: 32)),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: context.surfaceHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('🍕', style: TextStyle(fontSize: 32)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.isDark ? AppColors.surfaceHighDark : AppColors.dark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: AppColors.goldenCheese, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          pizza.rating.toString(),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                pizza.name,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: context.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 2),

              // Ingredients
              Text(
                pizza.ingredients.join(', '),
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: context.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Price & Quick Add
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '\$${pizza.price.toStringAsFixed(2)}',
                      style: AppTypography.price.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: onQuickAdd,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: AppColors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
