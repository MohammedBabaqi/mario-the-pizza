import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import '../models/cart_item_model.dart';
import '../viewmodels/pizza_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/customization_viewmodel.dart';
import '../services/pizza_service.dart';
import '../utils/app_snackbar.dart';

/// Pizza customization screen.
class CustomizationScreen extends StatefulWidget {
  final String pizzaId;
  const CustomizationScreen({super.key, required this.pizzaId});

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  late final CustomizationViewModel _customVM;
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _customVM = CustomizationViewModel();
      final pizza = context.read<PizzaViewModel>().getPizzaById(widget.pizzaId);
      final pizzaService = context.read<PizzaService>();
      if (pizza != null) {
        _customVM.initialize(pizza, pizzaService);
      }
      _inited = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _customVM,
      child: Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.pizzaId == 'craft_pizza' ? 'Craft Your Pizza 🎨' : 'Customize Pizza',
            style: AppTypography.headlineSmall.copyWith(color: context.text),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.text),
            onPressed: () => Navigation.goBack(context),
          ),
        ),
        body: Consumer<CustomizationViewModel>(
          builder: (context, vm, _) {
            if (vm.pizza == null) return const Center(child: Text('Pizza not found'));

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pizza name & live calorie badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vm.pizza!.name, style: AppTypography.displaySmall.copyWith(color: context.text, fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              vm.pizza!.description,
                              style: AppTypography.bodySmall.copyWith(color: context.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥 ', style: TextStyle(fontSize: 12)),
                            Text(
                              '${vm.totalCalories} kcal',
                              style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Size selection
                  Text('Size', style: AppTypography.titleLarge.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: PizzaSize.values.map((s) {
                      final selected = vm.size == s;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => vm.selectSize(s),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : context.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? AppColors.primary : context.border),
                            ),
                            child: Column(
                              children: [
                                Text(s.label, style: AppTypography.labelLarge.copyWith(color: selected ? AppColors.white : context.text)),
                                if (s.priceModifier > 0)
                                  Text('+\$${s.priceModifier.toStringAsFixed(2)}', style: AppTypography.labelSmall.copyWith(color: selected ? AppColors.cream : context.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Crust selection
                  Text('Crust', style: AppTypography.titleLarge.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CrustType.values.map((c) {
                      final selected = vm.crust == c;
                      return ChoiceChip(
                        label: Text(c.priceModifier > 0 ? '${c.label} (+\$${c.priceModifier.toStringAsFixed(2)})' : c.label),
                        selected: selected,
                        onSelected: (_) => vm.selectCrust(c),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: selected ? AppColors.white : context.text),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Sauce selection
                  Text('Sauce', style: AppTypography.titleLarge.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SauceType.values.map((s) {
                      final selected = vm.sauce == s;
                      return ChoiceChip(
                        label: Text(s.label),
                        selected: selected,
                        onSelected: (_) => vm.selectSauce(s),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: selected ? AppColors.white : context.text),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Dynamic Ingredients from Go API
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Extra Ingredients', style: AppTypography.titleLarge.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                      if (vm.isLoadingIngredients)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                    ],
                  ),
                  Text('Artisanal meats, cheeses & veggies from our kitchen', style: AppTypography.bodySmall.copyWith(color: context.textSecondary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: vm.availableIngredients.map((ing) {
                      final selected = vm.extraToppings.contains(ing.name);
                      final priceText = ing.priceModifier > 0 ? '+\$${ing.priceModifier.toStringAsFixed(2)}' : 'Free';
                      return FilterChip(
                        avatar: Text(ing.emoji, style: const TextStyle(fontSize: 16)),
                        label: Text('${ing.name} ($priceText)'),
                        selected: selected,
                        onSelected: (_) => vm.toggleTopping(ing.name),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.primary : context.text,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Consumer<CustomizationViewModel>(
          builder: (context, vm, _) {
            return Container(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              decoration: BoxDecoration(
                color: context.surface,
                border: Border(top: BorderSide(color: context.border)),
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: vm.pizza != null ? () {
                    final item = vm.buildCartItem();
                    context.read<CartViewModel>().addItem(item);
                    Navigation.goBack(context);
                    showMarioSnackBar(context, 'Custom ${vm.pizza!.name} added! 🎨');
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  child: Text('Add to Cart  ·  \$${vm.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
