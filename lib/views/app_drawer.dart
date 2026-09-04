import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/navigation.dart';
import '../utils/app_snackbar.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';

/// Navigation Drawer with interactive Profile Header and categorized links.
/// Requirement: Drawer, Navigation class methods.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final cartVM = context.watch<CartViewModel>();
    final user = authVM.user;
    final topPadding = MediaQuery.of(context).padding.top;

    return Drawer(
      backgroundColor: context.surface,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // ── 1. Interactive Profile Header (Top of Side Bar) ─────────────
          InkWell(
            onTap: () {
              Navigator.pop(context);
              if (authVM.isAuthenticated) {
                Navigation.goToProfile(context);
              } else {
                Navigation.goToSignIn(context);
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, topPadding + 18, 20, 20),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.goldenCheese, width: 2.5),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.white.withValues(alpha: 0.25),
                          child: Text(
                            authVM.isAuthenticated && (user?.displayName.isNotEmpty == true)
                                ? user!.displayName[0].toUpperCase()
                                : '🍕',
                            style: TextStyle(
                              fontSize: authVM.isAuthenticated ? 24 : 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              authVM.isAuthenticated ? 'Profile' : 'Sign In',
                              style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.white, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    authVM.isAuthenticated && (user?.displayName.isNotEmpty == true)
                        ? user!.displayName
                        : 'Welcome, Guest! 👋',
                    style: AppTypography.titleLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    authVM.isAuthenticated && (user?.email.isNotEmpty == true)
                        ? user!.email
                        : 'Tap here to sign in & save orders',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (authVM.isAuthenticated && user?.defaultAddress?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 12, color: AppColors.white),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              user!.defaultAddress!,
                              style: const TextStyle(color: AppColors.white, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Italian Tricolore Accent Ribbon 🇮🇹 ───────────────────
          Container(
            height: 3.5,
            decoration: const BoxDecoration(
              gradient: AppColors.tricoloreRibbon,
            ),
          ),

          // ── 2. Scrollable Navigation Sections ───────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Section: MENU
                _DrawerSectionHeader(title: 'MENU 🍕'),
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  onTap: () {
                    Navigator.pop(context);
                    Navigation.goToHome(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.explore_rounded,
                  label: 'Explore & Search',
                  onTap: () {
                    Navigator.pop(context);
                    Navigation.goToExplore(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Craft Your Pizza',
                  badgeText: 'HOT 🔥',
                  badgeColor: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigation.goToCustomization(context, 'craft_pizza');
                  },
                ),

                const Divider(height: 20),

                // Section: ACTIVITY
                _DrawerSectionHeader(title: 'MY ACTIVITY 📦'),
                _DrawerItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'My Orders',
                  onTap: () {
                    Navigator.pop(context);
                    Navigation.goToOrders(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.favorite_rounded,
                  label: 'Saved Favorites',
                  onTap: () {
                    Navigator.pop(context);
                    Navigation.goToFavorites(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.shopping_cart_rounded,
                  label: 'Shopping Cart',
                  badgeText: cartVM.hasItems ? '${cartVM.itemCount}' : null,
                  badgeColor: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigation.goToCart(context);
                  },
                ),

                const Divider(height: 20),

                // Section: ACCOUNT & SETTINGS
                _DrawerSectionHeader(title: 'ACCOUNT & SETTINGS ⚙️'),
                _DrawerItem(
                  icon: Icons.location_on_rounded,
                  label: 'Saved Delivery Addresses',
                  onTap: () {
                    Navigator.pop(context);
                    Navigation.goToLocationPicker(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.storage_rounded,
                  label: 'SQLite Database & Data',
                  badgeText: 'REAL DB',
                  badgeColor: AppColors.secondary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigation.goToDatabase(context);
                  },
                ),

                // Dark Mode Toggle Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        themeVM.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text('Dark Mode', style: AppTypography.titleMedium.copyWith(color: context.text)),
                      ),
                      Switch(
                        value: themeVM.isDark,
                        activeThumbColor: AppColors.primary,
                        onChanged: (_) => themeVM.toggleTheme(),
                      ),
                    ],
                  ),
                ),

                // Sign Out (if logged in)
                if (authVM.isAuthenticated) ...[
                  const Divider(height: 20),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    color: AppColors.primary,
                    onTap: () async {
                      Navigator.pop(context);
                      await authVM.signOut();
                      if (context.mounted) {
                        showMarioSnackBar(context, 'Signed out successfully');
                        Navigation.goToWelcome(context);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          // ── 3. Footer ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Mario Pizza Express v1.2.0 · Fresh & Hot 🍕',
              style: AppTypography.caption.copyWith(color: context.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  final String title;
  const _DrawerSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: context.textSecondary,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final String? badgeText;
  final Color? badgeColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? context.textSecondary, size: 22),
      title: Text(
        label,
        style: AppTypography.titleMedium.copyWith(color: color ?? context.text, fontSize: 14),
      ),
      trailing: badgeText != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText!,
                style: TextStyle(
                  color: badgeColor ?? AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }
}