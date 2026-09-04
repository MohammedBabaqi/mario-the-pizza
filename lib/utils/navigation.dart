import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../views/location_picker_screen.dart';

/// Navigation helper class with static methods.
/// Requirement: Navigation class methods.
class Navigation {
  Navigation._();

  static void goToHome(BuildContext context) => context.go('/home');
  static void goToExplore(BuildContext context) => context.go('/explore');
  static void goToOrders(BuildContext context) => context.go('/orders');
  static void goToFavorites(BuildContext context) => context.go('/favorites');
  static void goToCart(BuildContext context) => context.go('/cart');
  static void goToProfile(BuildContext context) => context.go('/profile');
  static void goToDatabase(BuildContext context) => context.push('/database');

  static void goToWelcome(BuildContext context) => context.go('/welcome');
  static void goToSignIn(BuildContext context) => context.go('/signin');
  static void goToSignUp(BuildContext context) => context.go('/signup');

  static void goToPizzaDetails(BuildContext context, String pizzaId) =>
      context.push('/pizza/$pizzaId');

  static void goToCustomization(BuildContext context, String pizzaId) =>
      context.push('/pizza/$pizzaId/customize');

  static void goToCheckout(BuildContext context) =>
      context.push('/checkout');

  static void goToOrderTracking(BuildContext context, String orderId) =>
      context.push('/orders/$orderId');

  static Future<String?> goToLocationPicker(BuildContext context, {String? initialAddress}) =>
      Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => LocationPickerScreen(initialAddress: initialAddress),
        ),
      );

  static void goBack(BuildContext context) => context.pop();

  static bool canGoBack(BuildContext context) => Navigator.of(context).canPop();
}
