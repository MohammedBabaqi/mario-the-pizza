import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/pizza_service.dart';
import 'services/order_service.dart';
import 'services/local_db_service.dart';
import 'services/prefs_service.dart';

import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/pizza_viewmodel.dart';
import 'viewmodels/cart_viewmodel.dart';
import 'viewmodels/order_viewmodel.dart';
import 'viewmodels/favorites_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';

import 'utils/app_theme.dart';

import 'views/welcome_screen.dart';
import 'views/sign_in_screen.dart';
import 'views/sign_up_screen.dart';
import 'views/home_screen.dart';
import 'views/search_screen.dart';
import 'views/pizza_details_screen.dart';
import 'views/customization_screen.dart';
import 'views/cart_screen.dart';
import 'views/checkout_screen.dart';
import 'views/orders_screen.dart';
import 'views/order_tracking_screen.dart';
import 'views/favorites_screen.dart';
import 'views/profile_screen.dart';
import 'views/location_picker_screen.dart';
import 'views/database_screen.dart';

/// App Router configuration using go_router.
/// Requirement: Navigation class methods.
final GoRouter _router = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/welcome',
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/explore',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrdersScreen(),
      routes: [
        GoRoute(
          path: ':orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId'] ?? '';
            return OrderTrackingScreen(orderId: orderId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/pizza/:pizzaId',
      builder: (context, state) {
        final pizzaId = state.pathParameters['pizzaId'] ?? '';
        return PizzaDetailsScreen(pizzaId: pizzaId);
      },
      routes: [
        GoRoute(
          path: 'customize',
          builder: (context, state) {
            final pizzaId = state.pathParameters['pizzaId'] ?? '';
            return CustomizationScreen(pizzaId: pizzaId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/location-picker',
      builder: (context, state) {
        final initialAddress = state.extra as String?;
        return LocationPickerScreen(initialAddress: initialAddress);
      },
    ),
    GoRoute(
      path: '/database',
      builder: (context, state) => const DatabaseScreen(),
    ),
  ],
);

/// Root Application Widget with MultiProvider MVVM architecture.
class MarioApp extends StatelessWidget {
  final PrefsService prefsService;
  final ApiService apiService;
  final LocalDbService localDbService;

  const MarioApp({
    super.key,
    required this.prefsService,
    required this.apiService,
    required this.localDbService,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(apiService, prefsService, localDbService);
    final pizzaService = PizzaService(apiService, localDbService);
    final orderService = OrderService(apiService);

    return MultiProvider(
      providers: [
        // Services
        Provider<PrefsService>.value(value: prefsService),
        Provider<ApiService>.value(value: apiService),
        Provider<LocalDbService>.value(value: localDbService),
        Provider<AuthService>.value(value: authService),
        Provider<PizzaService>.value(value: pizzaService),
        Provider<OrderService>.value(value: orderService),

        // ViewModels
        ChangeNotifierProvider<ThemeViewModel>(
          create: (_) => ThemeViewModel(prefsService),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(authService)..init(),
        ),
        ChangeNotifierProvider<PizzaViewModel>(
          create: (_) => PizzaViewModel(pizzaService)..loadPizzas(),
        ),
        ChangeNotifierProvider<CartViewModel>(
          create: (_) => CartViewModel(),
        ),
        ChangeNotifierProvider<OrderViewModel>(
          create: (_) => OrderViewModel(orderService, prefsService),
        ),
        ChangeNotifierProvider<CheckoutViewModel>(
          create: (_) => CheckoutViewModel(orderService),
        ),
        ChangeNotifierProvider<FavoritesViewModel>(
          create: (_) => FavoritesViewModel(prefsService)..loadFavorites(),
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, _) {
          return MaterialApp.router(
            title: 'MARIO Pizza',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeVM.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
