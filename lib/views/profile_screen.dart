import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import '../utils/app_snackbar.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../widgets/bottom_nav.dart';
import 'app_drawer.dart';

/// Profile Screen — User profile, settings, dark mode switch, and activity.
/// Requirement: Drawer, BottomNav, Card, Navigation class methods.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final user = authVM.user;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile 👤',
          style: AppTypography.headlineSmall.copyWith(
            color: context.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        children: [
          // User Avatar & Name Card (Card requirement)
          Card(
            color: context.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: context.border),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      authVM.isAuthenticated && (user?.displayName.isNotEmpty == true)
                          ? user!.displayName[0].toUpperCase()
                          : 'G',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authVM.isAuthenticated && (user?.displayName.isNotEmpty == true)
                              ? user!.displayName
                              : 'Guest User',
                          style: AppTypography.titleLarge.copyWith(
                            color: context.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authVM.isAuthenticated && (user?.email.isNotEmpty == true)
                              ? user!.email
                              : 'Sign in to sync your orders',
                          style: AppTypography.bodyMedium.copyWith(color: context.textSecondary),
                        ),
                        if (authVM.isAuthenticated) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'VIP Member 🍕',
                              style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Delivery & Contact Info Section
          if (authVM.isAuthenticated) ...[
            Text(
              'Delivery & Contact Info 📍',
              style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              color: context.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.border),
              ),
              elevation: 0,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    title: Text(
                      user?.phoneNumber?.isNotEmpty == true ? user!.phoneNumber! : 'Add phone number',
                      style: AppTypography.bodyMedium.copyWith(
                        color: user?.phoneNumber?.isNotEmpty == true ? context.text : context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text('Mobile phone for order delivery', style: AppTypography.caption.copyWith(color: context.textSecondary)),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _showEditPhoneDialog(context, authVM, user?.phoneNumber),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    title: Text(
                      user?.defaultAddress?.isNotEmpty == true ? user!.defaultAddress! : 'Select delivery location on map',
                      style: AppTypography.bodyMedium.copyWith(
                        color: user?.defaultAddress?.isNotEmpty == true ? context.text : context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('Default address for deliveries', style: AppTypography.caption.copyWith(color: context.textSecondary)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Map', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    onTap: () async {
                      final selectedAddress = await Navigation.goToLocationPicker(
                        context,
                        initialAddress: user?.defaultAddress,
                      );
                      if (selectedAddress != null && selectedAddress.isNotEmpty && context.mounted) {
                        await authVM.updateProfile(defaultAddress: selectedAddress);
                        if (context.mounted) {
                          showMarioSnackBar(context, 'Delivery location saved! 📍');
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // App Settings Section
          Text('Preferences', style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            color: context.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.border),
            ),
            elevation: 0,
            child: SwitchListTile(
              secondary: Icon(
                themeVM.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppColors.primary,
              ),
              title: Text('Dark Theme', style: AppTypography.bodyMedium.copyWith(color: context.text)),
              subtitle: Text(
                themeVM.isDark ? 'Currently Dark Mode' : 'Currently Light Mode',
                style: AppTypography.caption.copyWith(color: context.textSecondary),
              ),
              value: themeVM.isDark,
              activeThumbColor: AppColors.primary,
              onChanged: (_) => themeVM.toggleTheme(),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text('Activity', style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            color: context.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.border),
            ),
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                  title: Text('Order History', style: AppTypography.bodyMedium.copyWith(color: context.text)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigation.goToOrders(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.favorite_rounded, color: AppColors.primary),
                  title: Text('Saved Favorites', style: AppTypography.bodyMedium.copyWith(color: context.text)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigation.goToFavorites(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shopping_cart_rounded, color: AppColors.primary),
                  title: Text('Shopping Cart', style: AppTypography.bodyMedium.copyWith(color: context.text)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigation.goToCart(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage_rounded, color: AppColors.secondary),
                  title: Text('SQLite Database & Live Data 🗄️', style: AppTypography.bodyMedium.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                  subtitle: Text('View & manage real food items & users in SQLite', style: AppTypography.caption.copyWith(color: context.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigation.goToDatabase(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Auth Action Button
          if (authVM.isAuthenticated)
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              tileColor: AppColors.primary.withValues(alpha: 0.06),
              leading: const Icon(Icons.logout_rounded, color: AppColors.primary),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                await authVM.signOut();
                if (context.mounted) {
                  showMarioSnackBar(context, 'Signed out successfully');
                  Navigation.goToWelcome(context);
                }
              },
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Sign In / Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () => Navigation.goToSignIn(context),
            ),
          const SizedBox(height: 30),
        ],
      ),
      bottomNavigationBar: MarioBottomNav(
        currentIndex: -1,
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
              Navigation.goToCart(context);
              break;
          }
        },
      ),
    );
  }

  void _showEditPhoneDialog(BuildContext context, AuthViewModel authVM, String? currentPhone) {
    final controller = TextEditingController(text: currentPhone ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: const Text('Update Phone Number 📞'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '+1 234 567 8900',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newPhone = controller.text.trim();
              if (newPhone.isNotEmpty) {
                await authVM.updateProfile(phoneNumber: newPhone);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  showMarioSnackBar(context, 'Phone number updated! 📞');
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
