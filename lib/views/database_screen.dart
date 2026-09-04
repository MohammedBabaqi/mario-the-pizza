import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pizza_model.dart';
import '../models/user_model.dart';
import '../services/local_db_service.dart';
import '../viewmodels/pizza_viewmodel.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/app_snackbar.dart';

/// Interactive SQLite Database & Live Data Explorer Screen.
/// Allows direct viewing, inspection, adding, editing, and deleting of
/// real SQLite database records (Pizzas/Food and Users).
class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PizzaModel> _pizzas = [];
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDatabaseData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDatabaseData() async {
    setState(() => _isLoading = true);
    final db = context.read<LocalDbService>();
    final pizzas = await db.getCachedPizzas();
    final users = await db.getAllUsers();
    if (mounted) {
      setState(() {
        _pizzas = List.from(pizzas);
        _users = List.from(users);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SQLite Database & Data 🗄️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              kIsWeb ? 'Engine: Web Persistent LocalStorage DB' : 'Engine: SQLite native (mario_pizza.db)',
              style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload from SQLite',
            onPressed: _loadDatabaseData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textSecondary,
          tabs: [
            Tab(
              icon: const Icon(Icons.local_pizza_rounded, size: 20),
              text: 'Food (${_pizzas.length})',
            ),
            Tab(
              icon: const Icon(Icons.people_alt_rounded, size: 20),
              text: 'Users (${_users.length})',
            ),
            const Tab(
              icon: Icon(Icons.info_outline_rounded, size: 20),
              text: 'DB Info',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFoodTab(),
                _buildUsersTab(),
                _buildDbInfoTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Food Item', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showAddFoodDialog(context),
            )
          : null,
    );
  }

  // ── TAB 1: FOOD ITEMS (table: pizzas) ─────────────────────────────────

  Widget _buildFoodTab() {
    final filtered = _searchQuery.isEmpty
        ? _pizzas
        : _pizzas.where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search food in SQLite table...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: context.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),

        // Food items list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🍕', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('No food items found in SQLite', style: AppTypography.titleMedium.copyWith(color: context.text)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final pizza = filtered[index];
                    return Card(
                      color: context.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: context.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                pizza.imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, s) => Container(
                                  width: 70,
                                  height: 70,
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  child: const Center(child: Text('🍕', style: TextStyle(fontSize: 32))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          pizza.name,
                                          style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          pizza.category.toUpperCase(),
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${pizza.price.toStringAsFixed(2)} · ${pizza.calories} kcal · ★ ${pizza.rating}',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.goldenCheese, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pizza.ingredients.join(', '),
                                    style: AppTypography.caption.copyWith(color: context.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Actions (Edit, Delete)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 20),
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _showEditFoodDialog(context, pizza);
                                } else if (action == 'delete') {
                                  _confirmDeleteFood(context, pizza);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit Price/Name')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── TAB 2: USERS TABLE (table: users) ─────────────────────────────────

  Widget _buildUsersTab() {
    return _users.isEmpty
        ? Center(
            child: Text('No users in SQLite users table', style: AppTypography.titleMedium.copyWith(color: context.text)),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = _users[index];
              return Card(
                color: context.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: context.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '👤',
                              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName.isNotEmpty ? user.displayName : 'Guest User',
                                  style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  user.email,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            tooltip: 'Delete user from SQLite',
                            onPressed: () => _confirmDeleteUser(context, user),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Text(
                            user.phoneNumber?.isNotEmpty == true ? user.phoneNumber! : 'No phone registered',
                            style: AppTypography.caption.copyWith(color: context.text),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.defaultAddress?.isNotEmpty == true ? user.defaultAddress! : 'No address registered',
                              style: AppTypography.caption.copyWith(color: context.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'UID: ${user.uid} · Registered: ${user.createdAt.toLocal().toString().split('.')[0]}',
                        style: TextStyle(fontSize: 10, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  // ── TAB 3: DB INFO & MAINTENANCE ──────────────────────────────────────

  Widget _buildDbInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: context.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: context.border)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dns_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text('Database Engine Details', style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow('Database System', kIsWeb ? 'Browser Persistent SQLite Store' : 'SQLite 3 (sqflite)'),
                _buildInfoRow('Database File', 'mario_pizza.db'),
                _buildInfoRow('Active Food Table', 'pizzas (${_pizzas.length} records)'),
                _buildInfoRow('Active Users Table', 'users (${_users.length} records)'),
                _buildInfoRow('Database Version', 'v2'),
                _buildInfoRow('Status', '🟢 Online & Ready'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Schema Info
        Card(
          color: context.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: context.border)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.code_rounded, color: AppColors.secondary),
                    const SizedBox(width: 10),
                    Text('SQLite Schema Definitions', style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'CREATE TABLE pizzas (\n'
                    '  id TEXT PRIMARY KEY,\n'
                    '  name TEXT NOT NULL,\n'
                    '  price REAL NOT NULL,\n'
                    '  rating REAL NOT NULL,\n'
                    '  calories INTEGER NOT NULL,\n'
                    '  ingredients TEXT NOT NULL,\n'
                    '  category TEXT NOT NULL,\n'
                    '  imageUrl TEXT NOT NULL\n'
                    ');\n\n'
                    'CREATE TABLE users (\n'
                    '  uid TEXT PRIMARY KEY,\n'
                    '  email TEXT UNIQUE NOT NULL,\n'
                    '  displayName TEXT NOT NULL,\n'
                    '  phoneNumber TEXT,\n'
                    '  defaultAddress TEXT,\n'
                    '  createdAt TEXT NOT NULL\n'
                    ');',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Maintenance Action: Reset to Defaults
        OutlinedButton.icon(
          icon: const Icon(Icons.restore_rounded, color: AppColors.goldenCheese),
          label: const Text('Reset SQLite Database to Defaults'),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.text,
            side: const BorderSide(color: AppColors.goldenCheese),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _confirmResetDb(context),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: context.text, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // ── MODALS: ADD FOOD ITEM ─────────────────────────────────────────────

  void _showAddFoodDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '11.99');
    final calCtrl = TextEditingController(text: '750');
    final descCtrl = TextEditingController(text: 'Delicious freshly prepared authentic pizza');
    final imgCtrl = TextEditingController(text: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&h=600&fit=crop');
    final ingredientsCtrl = TextEditingController(text: 'Tomato Sauce, Mozzarella, Basil, Olive Oil');
    String category = 'classic';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add New Food Item 🍕', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: context.text)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Pizza / Dish Name', hintText: 'e.g. Buffalo Special')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price (\$)', prefixText: '\$ '))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories (kcal)'))),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'classic', child: Text('Classic 🇮🇹')),
                    DropdownMenuItem(value: 'spicy', child: Text('Spicy 🌶️')),
                    DropdownMenuItem(value: 'veggie', child: Text('Veggie 🥬')),
                    DropdownMenuItem(value: 'special', child: Text('Special ⭐')),
                  ],
                  onChanged: (val) => setSheetState(() => category = val ?? 'classic'),
                ),
                const SizedBox(height: 8),
                TextField(controller: ingredientsCtrl, decoration: const InputDecoration(labelText: 'Ingredients (comma-separated)', hintText: 'Cheese, Basil, Sauce')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save to SQLite Database 💾', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final price = double.tryParse(priceCtrl.text) ?? 9.99;
                    final cal = int.tryParse(calCtrl.text) ?? 700;
                    final ingredients = ingredientsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                    final newPizza = PizzaModel(
                      id: 'food_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      description: descCtrl.text.trim(),
                      price: price,
                      rating: 4.8,
                      calories: cal,
                      protein: 28,
                      fat: 22,
                      carbs: 75,
                      ingredients: ingredients,
                      category: category,
                      imageUrl: imgCtrl.text.trim(),
                      isPopular: true,
                      isRecommended: true,
                    );

                    // Insert directly into SQLite and update state
                    await context.read<PizzaViewModel>().addPizza(newPizza);
                    await _loadDatabaseData();
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      showMarioSnackBar(context, 'Food item "$name" saved to SQLite table! 🍕');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── MODALS: EDIT FOOD ITEM ────────────────────────────────────────────

  void _showEditFoodDialog(BuildContext context, PizzaModel pizza) {
    final nameCtrl = TextEditingController(text: pizza.name);
    final priceCtrl = TextEditingController(text: pizza.price.toStringAsFixed(2));
    final calCtrl = TextEditingController(text: pizza.calories.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: Text('Edit "${pizza.name}" ✏️'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price (\$)', prefixText: '\$ ')),
            const SizedBox(height: 8),
            TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
            child: const Text('Update SQLite'),
            onPressed: () async {
              final updated = PizzaModel(
                id: pizza.id,
                name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : pizza.name,
                description: pizza.description,
                price: double.tryParse(priceCtrl.text) ?? pizza.price,
                rating: pizza.rating,
                calories: int.tryParse(calCtrl.text) ?? pizza.calories,
                protein: pizza.protein,
                fat: pizza.fat,
                carbs: pizza.carbs,
                ingredients: pizza.ingredients,
                category: pizza.category,
                imageUrl: pizza.imageUrl,
                isPopular: pizza.isPopular,
                isRecommended: pizza.isRecommended,
              );
              await context.read<PizzaViewModel>().updatePizza(updated);
              await _loadDatabaseData();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                showMarioSnackBar(context, 'Food item updated in SQLite! 💾');
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFood(BuildContext context, PizzaModel pizza) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: const Text('Delete Food Item? 🗑️'),
        content: Text('Are you sure you want to permanently delete "${pizza.name}" from the SQLite table?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
            onPressed: () async {
              await context.read<PizzaViewModel>().deletePizza(pizza.id);
              await _loadDatabaseData();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                showMarioSnackBar(context, '"${pizza.name}" deleted from SQLite.');
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: const Text('Delete User? 👤'),
        content: Text('Delete user "${user.email}" from the SQLite users table?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
            onPressed: () async {
              await context.read<LocalDbService>().deleteUser(user.uid);
              await _loadDatabaseData();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                showMarioSnackBar(context, 'User deleted from SQLite users table.');
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmResetDb(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: const Text('Reset SQLite Database? ⚠️'),
        content: const Text('This will reset all food items and users in the SQLite database back to the initial defaults.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldenCheese, foregroundColor: Colors.black),
            child: const Text('Reset DB'),
            onPressed: () async {
              final localDb = context.read<LocalDbService>();
              final pizzaVM = context.read<PizzaViewModel>();
              await localDb.clearAll();
              await pizzaVM.loadPizzas();
              if (!mounted) return;
              await _loadDatabaseData();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                showMarioSnackBar(context, 'Database reset to default records successfully! 🍕');
              }
            },
          ),
        ],
      ),
    );
  }
}
