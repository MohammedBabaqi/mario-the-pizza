# 01 — Project Overview

## Product Name
**MARIO** — Premium Italian Pizza Delivery App

---

## Product Vision

> *"Hot. Fast. Yours."*

MARIO is not a generic food-delivery CRUD app. It is a **visually distinctive, playful, premium, modern pizza experience** that feels like a real funded startup — not a tutorial project.

### Brand Personality
| Attribute | Value |
|-----------|-------|
| Feel | Playful + Premium + Italian-inspired |
| Speed | Fast, instant mock data, smooth transitions |
| Color | Tomato Red + Basil Green + Warm Cream |
| Typography | Outfit (Google Fonts) — editorial weight |
| UX Tone | Friendly, confident, delightful |

---

## Technology Stack

```
Flutter SDK  ≥ 3.x
Dart SDK     ≥ 3.x

State Management:   flutter_bloc ^8.x (BLoC + Cubit)
Navigation:         go_router ^13.x
DI Container:       get_it ^7.x
Equality:           equatable ^2.x
Fonts:              google_fonts ^6.x
Backend (optional): Firebase (Auth + Firestore) — currently mocked
```

---

## Feature List

### ✅ Implemented
| Feature | Screen | Status |
|---------|--------|--------|
| Onboarding / Welcome | `WelcomeScreen` | ✅ Animated |
| Sign In | `SignInScreen` | ✅ BLoC-driven |
| Sign Up | `SignUpScreen` | ✅ |
| Home / Menu Browse | `HomeScreen` | ✅ Animated cards |
| Category Filtering | `HomeScreen` | ✅ Chip filter |
| Pizza Details | `PizzaDetailsScreen` | ✅ Hero transition |
| Pizza Customizer | `PizzaCustomizationScreen` | ✅ Real-time preview |
| Shopping Cart | `CartScreen` | ✅ Animated list |
| Promo Code | `CartScreen` | ✅ MARIO10, PIZZA5, FREESHIP |
| Checkout | `CheckoutScreen` | ✅ Address + Payment |
| Order Tracking | `OrderTrackingScreen` | ✅ Timeline progress |
| Order History | `OrdersScreen` | ✅ List view |
| Favorites | `FavoritesScreen` | ⚠️ Shell only |
| User Profile | `ProfileScreen` | ⚠️ Read-only |
| Dark Mode | — | ❌ Not implemented |
| Push Notifications | — | ❌ Not implemented |
| Real Firebase Backend | — | ❌ Mock only |

### ⚠️ Shell (placeholder) screens
- `FavoritesScreen` — shows empty state, no persistence
- `ProfileScreen` — displays user info, sign-out only

---

## Pizza Menu (Mock Data — 8 Pizzas)

| ID | Name | Price | Category | Toppings |
|----|------|-------|----------|---------|
| `margherita` | Margherita | $8.99 | classic | Tomato, Mozzarella, Basil |
| `pepperoni` | Pepperoni | $10.99 | classic | Pepperoni, Mozzarella |
| `four_cheese` | Four Cheese | $12.99 | special | Mozzarella, Gorgonzola, Parmesan, Fontina |
| `spicy_diavola` | Spicy Diavola | $11.99 | spicy | Salami, Chili, Red Pepper |
| `veggie_garden` | Veggie Garden | $9.99 | veggie | Bell Pepper, Mushrooms, Olives |
| `bbq_chicken` | BBQ Chicken | $13.99 | special | Chicken, BBQ Sauce, Red Onion |
| `mushroom_truffle` | Mushroom Truffle | $14.99 | special | Wild Mushrooms, Truffle Oil |
| `basil_special` | Basil Special | $11.49 | classic | Buffalo Mozzarella, Pesto, Basil |

---

## Pizza Customization Options

```
Sizes:   Small ($0 extra) | Medium (+$2.00) | Large (+$4.00)
Crusts:  Classic | Thin | Cheesy (+$1.50) | Stuffed (+$2.50)
Sauces:  Tomato | Spicy (+$0.50) | Creamy (+$0.50)
Toppings: +$1.00 each (Pepperoni, Mushrooms, Olives, Basil, Extra Cheese, Bell Pepper)
```

---

## Promo Codes
| Code | Discount |
|------|---------|
| `MARIO10` | 10% off subtotal |
| `PIZZA5` | $5.00 off |
| `FREESHIP` | Free delivery |

---

## Project Root Structure

```
pizza/
├── lib/
│   ├── main.dart               # Entry point
│   ├── app/
│   │   ├── app.dart            # Root widget (MultiBlocProvider)
│   │   ├── router.dart         # GoRouter configuration
│   │   └── theme/              # Design tokens
│   ├── blocs/                  # All BLoC/Cubit state machines
│   ├── core/widgets/           # Shared reusable widgets
│   ├── di/                     # GetIt service locator
│   └── features/               # Screen-level feature modules
└── packages/                   # Internal packages
    ├── cart_repository/
    ├── order_repository/
    ├── pizza_repository/
    └── user_repository/
```
