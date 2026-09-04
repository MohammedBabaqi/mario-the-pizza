import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import '../models/cart_item_model.dart';
import '../viewmodels/favorites_viewmodel.dart';
import '../viewmodels/pizza_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../widgets/pizza_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/bottom_nav.dart';
import '../utils/app_snackbar.dart';
import 'app_drawer.dart';

/// Favorites Screen — Displays user saved pizzas.
/// Requirement: GridView, Drawer, BottomNav, SharedPreferences storage.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favVM = context.watch<FavoritesViewModel>();
    final pizzaVM = context.watch<PizzaViewModel>();

    final favoritePizzas = pizzaVM.pizzas
        .where((pizza) => favVM.isFavorite(pizza.id))
        .toList();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Favorites ❤️',
          style: AppTypography.headlineSmall.copyWith(
            color: context.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: favoritePizzas.isEmpty
          ? const EmptyState(
              emoji: '💔',
              title: 'No Favorites Yet',
              subtitle: 'Tap the heart icon on any pizza to save your favorite picks here!',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: favoritePizzas.length,
              itemBuilder: (context, index) {
                final pizza = favoritePizzas[index];
                return PizzaCard(
                  pizza: pizza,
                  onTap: () => Navigation.goToPizzaDetails(context, pizza.id),
                  onQuickAdd: () {
                    context.read<CartViewModel>().addItem(
                          CartItemModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            pizza: pizza,
                          ),
                        );
                    showMarioSnackBar(context, '${pizza.name} added to cart! 🍕');
                  },
                );
              },
            ),
      bottomNavigationBar: MarioBottomNav(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigation.goToHome(context);
              break;
            case 1:
              Navigation.goToExplore(context);
              break;
            case 2:
              Navigation.goToOrders(context);
              break;
            case 3:
              break;
            case 4:
              Navigation.goToCart(context);
              break;
          }
        },
      ),
    );
  }
}
