import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import '../viewmodels/order_viewmodel.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/bottom_nav.dart';
import 'app_drawer.dart';

/// Orders Screen — List of past and active orders.
/// Requirement: ListView, Card, Drawer, BottomNavigationBar.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderViewModel>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderVM = context.watch<OrderViewModel>();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Orders 🍕',
          style: AppTypography.headlineSmall.copyWith(
            color: context.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Builder(
        builder: (context) {
          if (orderVM.isListLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (orderVM.listError != null && orderVM.orders.isEmpty) {
            return ErrorState(
              message: orderVM.listError!,
              onRetry: () => orderVM.loadOrders(),
            );
          }

          if (orderVM.orders.isEmpty) {
            return const EmptyState(
              emoji: '📦',
              title: 'No Orders Yet',
              subtitle: 'Place your first order to track it here!',
            );
          }

          // ListView requirement
          return RefreshIndicator(
            onRefresh: () => orderVM.loadOrders(),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              itemCount: orderVM.orders.length,
              itemBuilder: (context, index) {
                final order = orderVM.orders[index];
                return Card(
                  // Card requirement
                  color: context.surface,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.border),
                  ),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigation.goToOrderTracking(context, order.id),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                                style: AppTypography.titleMedium.copyWith(
                                  color: context.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(order.status.emoji, style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text(
                                      order.status.label,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'} • ${order.items.map((e) => e.pizzaName).take(2).join(', ')}${order.items.length > 2 ? '...' : ''}',
                            style: AppTypography.bodyMedium.copyWith(color: context.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')}',
                                style: AppTypography.caption.copyWith(color: context.textSecondary),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '\$${order.total.toStringAsFixed(2)}',
                                    style: AppTypography.price.copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: MarioBottomNav(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigation.goToHome(context);
              break;
            case 1:
              Navigation.goToExplore(context);
              break;
            case 2:
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
    );
  }
}
