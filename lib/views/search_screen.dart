import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import '../models/cart_item_model.dart';
import '../viewmodels/pizza_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/search_viewmodel.dart';
import '../services/prefs_service.dart';
import '../widgets/pizza_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/bottom_nav.dart';

/// Search / Explore screen.
/// Requirement: GridView.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pizzas = context.watch<PizzaViewModel>().pizzas;
    final prefs = context.read<PrefsService>();

    return ChangeNotifierProvider<SearchViewModel>(
      create: (_) => SearchViewModel(pizzas, prefs),
      child: const _SearchScreenView(),
    );
  }
}

class _SearchScreenView extends StatefulWidget {
  const _SearchScreenView();

  @override
  State<_SearchScreenView> createState() => _SearchScreenViewState();
}

class _SearchScreenViewState extends State<_SearchScreenView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      // AppBar requirement
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppConstants.screenPadding,
        title: Text(
          'Search & Explore 🔍',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold, color: context.text),
        ),
        actions: [
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
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
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
      body: Consumer<SearchViewModel>(
        builder: (context, searchVM, _) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Search bar & filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Input
                      Container(
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: context.text),
                          onChanged: searchVM.updateQuery,
                          onSubmitted: searchVM.saveRecentSearch,
                          decoration: InputDecoration(
                            hintText: 'Search pizza, pepperoni, truffles...',
                            hintStyle: AppTypography.bodyMedium.copyWith(color: context.textSecondary),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      searchVM.updateQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recent Searches
                      if (searchVM.recentSearches.isNotEmpty && searchVM.query.isEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Searches', style: AppTypography.labelLarge.copyWith(color: context.textSecondary)),
                            GestureDetector(
                              onTap: searchVM.clearRecentSearches,
                              child: Text('Clear', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: searchVM.recentSearches.map((term) {
                            return ActionChip(
                              label: Text(term),
                              avatar: const Icon(Icons.history_rounded, size: 14, color: AppColors.grey),
                              onPressed: () {
                                _searchController.text = term;
                                searchVM.updateQuery(term);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Category & Sort Row
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildCategoryChip(searchVM, 'all', '🍕 All'),
                                  _buildCategoryChip(searchVM, 'classic', '🇮🇹 Classic'),
                                  _buildCategoryChip(searchVM, 'spicy', '🌶️ Spicy'),
                                  _buildCategoryChip(searchVM, 'special', '⭐ Special'),
                                  _buildCategoryChip(searchVM, 'veggie', '🌿 Veggie'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<PizzaSortOption>(
                            initialValue: searchVM.sortOption,
                            onSelected: searchVM.setSortOption,
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.tune_rounded, color: AppColors.white, size: 18),
                            ),
                            itemBuilder: (_) => PizzaSortOption.values
                                .map((opt) => PopupMenuItem(value: opt, child: Text(opt.label, style: AppTypography.labelMedium)))
                                .toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('${searchVM.results.length} Pizzas Found', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: context.text)),
                    ],
                  ),
                ),
              ),

              // GridView Requirement
              if (searchVM.results.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(emoji: '🔍', title: 'No pizzas found', subtitle: 'Try a different search term or filter.'),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pizza = searchVM.results[index];
                        return PizzaCard(
                          pizza: pizza,
                          width: null,
                          margin: EdgeInsets.zero,
                          onTap: () {
                            if (_searchController.text.isNotEmpty) searchVM.saveRecentSearch(_searchController.text);
                            Navigation.goToPizzaDetails(context, pizza.id);
                          },
                          onQuickAdd: () {
                            final item = CartItemModel(id: DateTime.now().millisecondsSinceEpoch.toString(), pizza: pizza);
                            context.read<CartViewModel>().addItem(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${pizza.name} added! 🍕'),
                                duration: const Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.secondary,
                                action: SnackBarAction(
                                  label: 'VIEW CART 🛒',
                                  textColor: AppColors.white,
                                  onPressed: () => Navigation.goToCart(context),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: searchVM.results.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: MarioBottomNav(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigation.goToHome(context);
              break;
            case 1:
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
    );
  }

  Widget _buildCategoryChip(SearchViewModel searchVM, String categoryId, String label) {
    final isSelected = searchVM.selectedCategory == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => searchVM.selectCategory(categoryId),
        selectedColor: AppColors.primary,
        backgroundColor: context.surface,
        side: BorderSide(color: isSelected ? AppColors.primary : context.border),
        labelStyle: AppTypography.labelMedium.copyWith(color: isSelected ? AppColors.white : context.text),
      ),
    );
  }
}
