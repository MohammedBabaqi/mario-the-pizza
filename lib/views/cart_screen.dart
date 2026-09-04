import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/empty_state.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/mario_button.dart';
import '../utils/app_snackbar.dart';

/// Cart screen with ListView.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.text),
          onPressed: () {
            if (Navigation.canGoBack(context)) {
              Navigation.goBack(context);
            } else {
              Navigation.goToHome(context);
            }
          },
        ),
        title: Text('My Cart 🛒', style: AppTypography.headlineSmall.copyWith(color: context.text, fontWeight: FontWeight.bold)),
        actions: [
          Consumer<CartViewModel>(
            builder: (context, cartVM, _) {
              if (cartVM.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.secondary, size: 20),
                label: const Text('Clear All', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                onPressed: () {
                  cartVM.clearCart();
                  showMarioSnackBar(context, 'All items removed from cart');
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<CartViewModel>(
        builder: (context, cartVM, _) {
          if (cartVM.isEmpty) {
            return EmptyState(
              emoji: '🛒',
              title: 'Your cart is empty',
              subtitle: 'Add some delicious handcrafted pizzas to get started!',
              actionLabel: 'Browse Pizzas 🍕',
              onAction: () => Navigation.goToHome(context),
            );
          }

          // ListView requirement
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            itemCount: cartVM.items.length,
            itemBuilder: (context, index) {
              final item = cartVM.items[index];
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_rounded, color: AppColors.white),
                ),
                onDismissed: (_) {
                  cartVM.removeItem(item.id);
                  showMarioSnackBar(context, '${item.pizza.name} removed from cart');
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: item.pizza.imageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 70,
                            height: 70,
                            color: context.surfaceHigh,
                            child: const Center(child: Text('🍕', style: TextStyle(fontSize: 28))),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 70,
                            height: 70,
                            color: context.surfaceHigh,
                            child: const Center(child: Text('🍕', style: TextStyle(fontSize: 28))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.pizza.name, style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(item.customizationSummary, style: AppTypography.bodySmall.copyWith(color: context.textSecondary)),
                            const SizedBox(height: 6),
                            Text('\$${item.itemTotal.toStringAsFixed(2)}', style: AppTypography.price.copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.primary, size: 20),
                            tooltip: 'Remove',
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              cartVM.removeItem(item.id);
                              showMarioSnackBar(context, '${item.pizza.name} removed from cart');
                            },
                          ),
                          const SizedBox(height: 4),
                          QuantityStepper(
                            quantity: item.quantity,
                            onChanged: (q) => cartVM.updateQuantity(item.id, q),
                            onDelete: () {
                              cartVM.removeItem(item.id);
                              showMarioSnackBar(context, '${item.pizza.name} removed from cart');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<CartViewModel>(
            builder: (context, cartVM, _) {
              if (cartVM.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(AppConstants.screenPadding),
                decoration: BoxDecoration(
                  color: context.surface,
                  border: Border(top: BorderSide(color: context.border)),
                ),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: AppTypography.bodyMedium.copyWith(color: context.textSecondary)),
                          Text('\$${cartVM.subtotal.toStringAsFixed(2)}', style: AppTypography.bodyMedium.copyWith(color: context.text)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Delivery', style: AppTypography.bodyMedium.copyWith(color: context.textSecondary)),
                          Text(
                            cartVM.deliveryFee == 0 ? 'FREE' : '\$${cartVM.deliveryFee.toStringAsFixed(2)}',
                            style: AppTypography.bodyMedium.copyWith(color: cartVM.deliveryFee == 0 ? AppColors.secondary : context.text),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: AppTypography.titleLarge.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                          Text('\$${cartVM.total.toStringAsFixed(2)}', style: AppTypography.price.copyWith(fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MarioButton(
                        label: 'Proceed to Checkout 🍕',
                        onPressed: () => Navigation.goToCheckout(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          MarioBottomNav(
            currentIndex: 4,
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
                  Navigation.goToFavorites(context);
                  break;
                case 4:
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}
