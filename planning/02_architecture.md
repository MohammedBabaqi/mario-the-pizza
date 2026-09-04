# 02 — Architecture

## Pattern: Clean Architecture + BLoC

MARIO follows **Clean Architecture** divided into three dependency layers:

```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │
│  Screens + Widgets + BLoC/Cubit         │
│  (lib/features/, lib/blocs/)            │
└──────────────┬──────────────────────────┘
               │ depends on
┌──────────────▼──────────────────────────┐
│          DOMAIN LAYER                   │
│  Repository Interfaces (Base classes)   │
│  Entity classes (pure Dart)             │
│  (packages/*/lib/src/entities/)         │
└──────────────┬──────────────────────────┘
               │ depends on
┌──────────────▼──────────────────────────┐
│           DATA LAYER                    │
│  Mock / Firebase implementations        │
│  (packages/*/lib/src/datasources/)      │
└─────────────────────────────────────────┘
```

---

## Folder Structure — Detailed

```
lib/
│
├── main.dart                        # Entry: init DI → runApp(MarioApp)
│
├── app/
│   ├── app.dart                     # MarioApp: MultiBlocProvider + MaterialApp.router
│   ├── router.dart                  # GoRouter: all routes, auth redirect, ShellRoute
│   └── theme/
│       ├── app_colors.dart          # Color tokens
│       ├── app_typography.dart      # TextStyle tokens (Outfit font)
│       ├── app_spacing.dart         # Spacing constants
│       ├── app_radius.dart          # BorderRadius tokens
│       ├── app_shadows.dart         # BoxShadow tokens
│       ├── app_durations.dart       # Animation duration tokens
│       └── app_theme.dart           # ThemeData composition
│
├── blocs/
│   ├── authentication/
│   │   ├── authentication_bloc.dart  # Listens to user stream
│   │   ├── authentication_event.dart
│   │   └── authentication_state.dart
│   ├── sign_in/
│   │   ├── sign_in_bloc.dart
│   │   ├── sign_in_event.dart
│   │   └── sign_in_state.dart
│   ├── sign_up/
│   │   ├── sign_up_bloc.dart
│   │   ├── sign_up_event.dart
│   │   └── sign_up_state.dart
│   ├── get_pizza/
│   │   ├── get_pizza_bloc.dart       # Menu fetch + category filter
│   │   ├── get_pizza_event.dart
│   │   └── get_pizza_state.dart
│   ├── pizza_customization/
│   │   ├── pizza_customization_cubit.dart  # Simple Cubit, no events
│   │   └── pizza_customization_state.dart
│   ├── cart/
│   │   ├── cart_bloc.dart            # Listens to cart stream
│   │   ├── cart_event.dart
│   │   └── cart_state.dart
│   ├── checkout/
│   │   ├── checkout_bloc.dart
│   │   ├── checkout_event.dart
│   │   └── checkout_state.dart
│   ├── order/
│   │   ├── order_bloc.dart           # History list
│   │   ├── order_event.dart
│   │   └── order_state.dart
│   └── order_tracking/
│       ├── order_tracking_bloc.dart  # Real-time stream subscription
│       ├── order_tracking_event.dart
│       └── order_tracking_state.dart
│
├── core/widgets/                     # Shared design system components
│   ├── abstract_blob.dart            # Decorative blob shape + FloatingIngredientParticle
│   ├── mario_bottom_nav.dart         # Custom floating bottom nav with cart badge
│   ├── mario_button.dart             # Primary CTA button with scale micro-interaction
│   ├── mario_empty_state.dart        # Empty state card
│   ├── mario_error_state.dart        # Error state with retry
│   ├── mario_loader.dart             # Branded rotating pizza loader
│   ├── mario_shimmer.dart            # Loading skeleton
│   ├── mario_text_field.dart         # Branded input field
│   ├── order_timeline.dart           # Vertical tracking timeline
│   ├── pizza_card.dart               # Horizontal scroll pizza card
│   ├── pizza_illustration.dart       # CustomPainter vector pizza
│   └── quantity_stepper.dart         # Cart +/- stepper
│
├── di/
│   └── service_locator.dart          # GetIt registrations
│
└── features/
    ├── onboarding/welcome_screen.dart
    ├── auth/
    │   ├── sign_in_screen.dart
    │   └── sign_up_screen.dart
    ├── home/home_screen.dart
    ├── pizza_details/pizza_details_screen.dart
    ├── customization/pizza_customization_screen.dart
    ├── cart/cart_screen.dart
    ├── checkout/checkout_screen.dart
    ├── order_tracking/order_tracking_screen.dart
    ├── orders/orders_screen.dart
    ├── favorites/favorites_screen.dart
    └── profile/profile_screen.dart

packages/
├── user_repository/
│   └── lib/src/
│       ├── entities/user_entity.dart
│       ├── datasources/
│       │   ├── mock_user_data_source.dart
│       │   └── firebase_user_data_source.dart
│       └── user_repository_base.dart
├── pizza_repository/
│   └── lib/src/
│       ├── entities/
│       │   ├── pizza_entity.dart
│       │   ├── category_entity.dart
│       │   └── ingredient_entity.dart
│       ├── datasources/
│       │   ├── mock_pizza_data_source.dart
│       │   └── firebase_pizza_data_source.dart
│       └── pizza_repository_base.dart
├── cart_repository/
│   └── lib/src/
│       ├── entities/
│       │   ├── cart_entity.dart
│       │   └── cart_item_entity.dart (+ PizzaSize, CrustType, SauceType enums)
│       ├── datasources/cart_data_source.dart
│       └── cart_repository_base.dart
└── order_repository/
    └── lib/src/
        ├── entities/order_entity.dart (+ OrderStatus, OrderTrackingStep)
        ├── datasources/
        │   ├── mock_order_data_source.dart
        │   └── firebase_order_data_source.dart
        └── order_repository_base.dart
```

---

## Dependency Injection Flow

```
main() 
  └── initServiceLocator(useMock: true)
        ├── sl.register<UserRepositoryBase>   → MockUserDataSource
        ├── sl.register<PizzaRepositoryBase>  → MockPizzaDataSource
        ├── sl.register<OrderRepositoryBase>  → MockOrderDataSource
        ├── sl.register<CartRepositoryBase>   → CartDataSource (always in-memory)
        ├── sl.register<AuthenticationBloc>   (factory)
        ├── sl.register<SignInBloc>            (factory)
        ├── sl.register<SignUpBloc>            (factory)
        ├── sl.register<GetPizzaBloc>          (factory)
        ├── sl.register<PizzaCustomizationCubit> (factory)
        ├── sl.register<CartBloc>              (factory)
        ├── sl.register<CheckoutBloc>          (factory)
        ├── sl.register<OrderBloc>             (factory)
        └── sl.register<OrderTrackingBloc>     (factory)

runApp(MarioApp)
  └── MultiBlocProvider (provides all 9 blocs at root)
        └── MaterialApp.router (GoRouter)
```

---

## Navigation Architecture (GoRouter)

```
GoRouter
├── /welcome                          (WelcomeScreen) — auth route
├── /signin                           (SignInScreen)  — auth route
├── /signup                           (SignUpScreen)  — auth route
│
├── ShellRoute → _MarioShell (bottom nav)
│   ├── /home                         (HomeScreen)
│   ├── /explore                      (HomeScreen alias)
│   ├── /orders                       (OrdersScreen)
│   │   └── /orders/:id               (OrderTrackingScreen)
│   ├── /favorites                    (FavoritesScreen)
│   ├── /cart                         (CartScreen)   ← inside shell (fixed)
│   └── /profile                      (ProfileScreen)
│
├── /pizza/:id                        (PizzaDetailsScreen) — standalone
│   └── /pizza/:id/customize          (PizzaCustomizationScreen) — standalone
│
└── /checkout                         (CheckoutScreen) — standalone

Auth Redirect Rules:
  unauthenticated + !authRoute  → /welcome
  authenticated   + authRoute   → /home
  status == unknown             → no redirect (wait)
```

---

## BLoC Communication Pattern

```
AuthenticationBloc ──stream──► GoRouter refreshListenable
       │
       ▼
  AuthStatus.authenticated
       │
       ▼ (router allows access)
  HomeScreen
       │
       ├── GetPizzaBloc.add(GetPizzasRequested) ← initState
       ├── CartBloc (read item count for badge)
       └── AuthenticationBloc (read user name)
```

---

## State Flow: Add to Cart

```
User taps "Add to Cart" (PizzaDetailsScreen)
  └── CartBloc.add(CartItemAdded(item))
        └── CartDataSource.addItem(item)   [async]
              └── _cartController.add(updatedCart)  [stream]
                    └── CartBloc._onCartUpdated(event, emit)
                          └── emit(CartState(cart: updatedCart))
                                └── MarioBottomNav rebuilds (cart badge count)
                                └── CartScreen rebuilds (if open)
```
