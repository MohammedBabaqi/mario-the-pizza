import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import '../viewmodels/order_viewmodel.dart';
import '../widgets/mario_button.dart';

/// Order Tracking Screen.
/// Requirement: Passing parameters (orderId), Cards, Navigation.
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderViewModel>().loadOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderVM = context.watch<OrderViewModel>();
    final order = orderVM.trackedOrder;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.text),
          onPressed: () => Navigation.goToOrders(context),
        ),
        title: Text(
          'Track Order',
          style: AppTypography.headlineSmall.copyWith(
            color: context.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: order == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              children: [
                // Top status card
                Card(
                  color: context.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: context.border),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          order.status.emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          order.status.label,
                          style: AppTypography.headlineSmall.copyWith(
                            color: context.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Estimated Delivery: ${order.estimatedMinutesRemaining > 0 ? '${order.estimatedMinutesRemaining} mins' : 'Arrived!'}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: order.progress,
                            backgroundColor: context.surfaceHigh,
                            color: AppColors.primary,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Order Timeline Steps
                Text(
                  'Order Status',
                  style: AppTypography.titleMedium.copyWith(
                    color: context.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: context.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.border),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: OrderStatus.values.map((step) {
                        final stepIndex = OrderStatus.values.indexOf(step);
                        final currentIndex = order.currentStepIndex;
                        final isCompleted = stepIndex <= currentIndex;
                        final isCurrent = stepIndex == currentIndex;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? AppColors.primary
                                      : context.surfaceHigh,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? const Icon(Icons.check_rounded, color: AppColors.white, size: 20)
                                      : Text(
                                          '${stepIndex + 1}',
                                          style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  '${step.emoji} ${step.label}',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isCompleted ? context.text : context.textSecondary,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Delivery Info Card
                Text(
                  'Delivery Details',
                  style: AppTypography.titleMedium.copyWith(
                    color: context.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: context.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.border),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Delivery Address', style: AppTypography.caption.copyWith(color: context.textSecondary)),
                                  const SizedBox(height: 2),
                                  Text(order.deliveryAddress, style: AppTypography.bodyMedium.copyWith(color: context.text)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.payment_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Method', style: AppTypography.caption.copyWith(color: context.textSecondary)),
                                const SizedBox(height: 2),
                                Text(order.paymentMethod, style: AppTypography.bodyMedium.copyWith(color: context.text)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Order Items Summary
                Text(
                  'Ordered Items (${order.items.length})',
                  style: AppTypography.titleMedium.copyWith(
                    color: context.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: context.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.border),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.quantity}x ${item.pizzaName} (${item.size})',
                                    style: AppTypography.bodyMedium.copyWith(color: context.text),
                                  ),
                                  Text(
                                    '\$${item.itemTotal.toStringAsFixed(2)}',
                                    style: AppTypography.bodyMedium.copyWith(color: context.text, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Paid', style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                            Text('\$${order.total.toStringAsFixed(2)}', style: AppTypography.price.copyWith(fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                MarioButton(
                  label: 'Back to Home',
                  onPressed: () => Navigation.goToHome(context),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
