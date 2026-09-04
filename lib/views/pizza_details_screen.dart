import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import '../models/cart_item_model.dart';
import '../viewmodels/pizza_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/favorites_viewmodel.dart';
import '../utils/app_snackbar.dart';

/// Pizza Details screen.
/// Requirements: Passing parameters (receives pizzaId), Card.
class PizzaDetailsScreen extends StatelessWidget {
  final String pizzaId;

  const PizzaDetailsScreen({super.key, required this.pizzaId});

  @override
  Widget build(BuildContext context) {
    final pizzaVM = context.watch<PizzaViewModel>();
    final favVM = context.watch<FavoritesViewModel>();
    final pizza = pizzaVM.getPizzaById(pizzaId);

    if (pizza == null) {
      return Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Pizza not found 🍕')),
      );
    }

    final isFav = favVM.isFavorite(pizza.id);

    return Scaffold(
      backgroundColor: context.bg,
      body: CustomScrollView(
        slivers: [
          // Hero image with sliver app bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: context.bg,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.surface.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_rounded, color: context.text),
              ),
              onPressed: () => Navigation.goBack(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.surface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? AppColors.secondary : context.text),
                ),
                onPressed: () => favVM.toggle(pizza.id),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'pizza_hero_${pizza.id}',
                child: CachedNetworkImage(
                  imageUrl: pizza.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: context.surfaceHigh,
                    child: const Center(child: Text('🍕', style: TextStyle(fontSize: 64))),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: context.surfaceHigh,
                    child: const Center(child: Text('🍕', style: TextStyle(fontSize: 64))),
                  ),
                ),
              ),
            ),
          ),

          // Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pizza.name,
                          style: AppTypography.displaySmall.copyWith(color: context.text, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('\$${pizza.price.toStringAsFixed(2)}', style: AppTypography.price.copyWith(fontSize: 24)),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Rating and Calories
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.goldenCheese, size: 18),
                      const SizedBox(width: 4),
                      Text('${pizza.rating}', style: AppTypography.labelLarge.copyWith(color: context.text)),
                      const SizedBox(width: 16),
                      Text('·', style: TextStyle(color: context.textSecondary, fontSize: 18)),
                      const SizedBox(width: 16),
                      Icon(Icons.local_fire_department, color: AppColors.primary, size: 18),
                      const SizedBox(width: 4),
                      Text('${pizza.calories} cal', style: AppTypography.labelLarge.copyWith(color: context.textSecondary)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(pizza.description, style: AppTypography.bodyLarge.copyWith(color: context.textSecondary, height: 1.6)),

                  const SizedBox(height: 20),

                  // Ingredients
                  Text('Ingredients', style: AppTypography.titleLarge.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pizza.ingredients.map((ing) {
                      return Chip(
                        label: Text(ing),
                        backgroundColor: context.surfaceHigh,
                        side: BorderSide(color: context.border),
                        labelStyle: AppTypography.labelMedium.copyWith(color: context.text),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Nutrition Cards (Card requirement)
                  Text('Nutrition Info', style: AppTypography.titleLarge.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _NutritionCard(label: 'Calories', value: '${pizza.calories}', icon: '🔥', color: AppColors.primary),
                      const SizedBox(width: 10),
                      _NutritionCard(label: 'Protein', value: '${pizza.protein}g', icon: '💪', color: AppColors.secondary),
                      const SizedBox(width: 10),
                      _NutritionCard(label: 'Fat', value: '${pizza.fat}g', icon: '🧈', color: AppColors.goldenCheese),
                      const SizedBox(width: 10),
                      _NutritionCard(label: 'Carbs', value: '${pizza.carbs}g', icon: '🌾', color: const Color(0xFF6366F1)),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        decoration: BoxDecoration(
          color: context.surface,
          border: Border(top: BorderSide(color: context.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Customize button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigation.goToCustomization(context, pizza.id),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Customize'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Add to cart button
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        final item = CartItemModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          pizza: pizza,
                        );
                        context.read<CartViewModel>().addItem(item);
                        showMarioSnackBar(context, '${pizza.name} added to cart! 🍕');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_rounded, color: AppColors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add  ·  \$${pizza.price.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _NutritionCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(value, style: AppTypography.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label, style: AppTypography.labelSmall.copyWith(color: context.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
