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
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/pizza_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_state.dart';
import '../widgets/bottom_nav.dart';
import '../utils/app_snackbar.dart';
import 'app_drawer.dart';

/// Home screen with horizontal pizza list and categories.
/// Requirement: ListView, Card, Navigation class methods, Drawer.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final userName = authVM.user?.displayName ?? 'Guest';

    return Scaffold(
      backgroundColor: context.bg,
      // AppBar requirement
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: context.text),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: GestureDetector(
          onTap: () async {
            final result = await Navigation.goToLocationPicker(context);
            if (result != null) {
              if (authVM.isAuthenticated && authVM.user != null) {
                await authVM.updateProfile(defaultAddress: result);
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14),
                  const SizedBox(width: 4),
                  Text('DELIVER TO', style: AppTypography.labelSmall.copyWith(color: context.textSecondary, letterSpacing: 1)),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: context.textSecondary),
                ],
              ),
              Text(
                authVM.user?.defaultAddress?.isNotEmpty == true
                    ? authVM.user!.defaultAddress!
                    : 'Select Delivery Location',
                style: AppTypography.titleSmall.copyWith(color: context.text, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        actions: [
          // Cart button with badge
          Consumer<CartViewModel>(
            builder: (context, cartVM, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_rounded),
                    color: context.text,
                    tooltip: 'View Cart',
                    onPressed: () => Navigation.goToCart(context),
                  ),
                  if (cartVM.hasItems)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '${cartVM.itemCount}',
                          style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Drawer requirement
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<PizzaViewModel>().loadPizzas(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(userName),
                        style: AppTypography.bodyMedium.copyWith(color: context.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Craving something fresh?',
                        style: AppTypography.displaySmall.copyWith(color: context.text),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Hero Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                  child: _HeroBanner(),
                ),

                const SizedBox(height: 24),

                // Categories Horizontal Scroll (ListView requirement)
                Consumer<PizzaViewModel>(
                  builder: (context, pizzaVM, _) {
                    return SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                        itemCount: pizzaVM.categories.length,
                        itemBuilder: (context, index) {
                          final category = pizzaVM.categories[index];
                          final isSelected = category.id == pizzaVM.selectedCategoryId;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label: Text('${category.emoji} ${category.name}'),
                              selected: isSelected,
                              onSelected: (_) => pizzaVM.loadPizzasByCategory(category.id),
                              backgroundColor: context.surface,
                              selectedColor: AppColors.primary,
                              labelStyle: AppTypography.labelLarge.copyWith(
                                color: isSelected ? AppColors.white : context.text,
                              ),
                              side: BorderSide(color: isSelected ? AppColors.primary : context.border),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Popular Pizzas Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Popular Right Now 🔥', style: AppTypography.headlineSmall.copyWith(color: context.text)),
                      GestureDetector(
                        onTap: () => Navigation.goToExplore(context),
                        child: Text('See all', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Horizontal Pizza ListView (ListView requirement)
                Consumer<PizzaViewModel>(
                  builder: (context, pizzaVM, _) {
                    if (pizzaVM.isLoading) {
                      return SizedBox(
                        height: 270,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                          itemCount: 3,
                          itemBuilder: (_, i) => const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: ShimmerLoading(width: 210, height: 260),
                          ),
                        ),
                      );
                    }

                    if (pizzaVM.hasError) {
                      return ErrorState(
                        message: pizzaVM.errorMessage ?? 'Failed to load',
                        onRetry: () => pizzaVM.loadPizzas(),
                      );
                    }

                    return SizedBox(
                      height: 270,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                        itemCount: pizzaVM.pizzas.length,
                        itemBuilder: (context, index) {
                          final pizza = pizzaVM.pizzas[index];
                          return PizzaCard(
                            pizza: pizza,
                            onTap: () => Navigation.goToPizzaDetails(context, pizza.id),
                            onQuickAdd: () {
                              final item = CartItemModel(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                pizza: pizza,
                              );
                              context.read<CartViewModel>().addItem(item);
                              showMarioSnackBar(context, '${pizza.name} added to cart! 🍕');
                            },
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Build Your Own CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                  child: GestureDetector(
                    onTap: () {
                      Navigation.goToCustomization(context, 'craft_pizza');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '🇮🇹 ARTISANAL',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.cream,
                                          letterSpacing: 1.2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Craft Your Own\nMasterpiece',
                                  style: AppTypography.headlineSmall.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.goldenCheese.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.dark, size: 26),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Consumer<CartViewModel>(
        builder: (context, cartVM, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cartVM.hasItems)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigation.goToCart(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${cartVM.itemCount} items',
                              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '\$${cartVM.total.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Spacer(),
                          const Text('View Cart 🛒', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              MarioBottomNav(
                currentIndex: 0,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      break;
                    case 1:
                      Navigation.goToExplore(context);
                      break;
                    case 2:
                      Navigation.goToOrders(context);
                      break;
                    case 3:
                      Navigation.goToFavorites(context);
                      break;
                    case 4:
                      Navigation.goToCart(context);
                      break;
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $name 🌅';
    if (hour < 17) return 'Good afternoon, $name ☀️';
    return 'Good evening, $name 👋';
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 165,
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned(right: -20, top: -20, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.07)))),
          Positioned(
            right: 10,
            bottom: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=300&h=300&fit=crop',
                width: 130,
                height: 130,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(width: 130, height: 130, child: Center(child: Text('🍕', style: TextStyle(fontSize: 48)))),
                errorWidget: (context, url, error) => const SizedBox(width: 130, height: 130, child: Center(child: Text('🍕', style: TextStyle(fontSize: 48)))),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.goldenCheese, borderRadius: BorderRadius.circular(8)),
                  child: Text('30% OFF FIRST ORDER', style: AppTypography.labelSmall.copyWith(color: AppColors.dark, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Text('MARIO\nHOT & FRESH', style: AppTypography.headlineMedium.copyWith(color: AppColors.white, height: 1.1, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Today\'s special deal 🔥', style: AppTypography.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

