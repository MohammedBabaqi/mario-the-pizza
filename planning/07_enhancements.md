# 07 — Enhancement Wishlist

> This document catalogs all desired improvements with priority, difficulty, and implementation guidance.
> Use `08_chatgpt_prompts.md` for ready-to-paste AI prompts for each item.

---

## Priority Matrix

| # | Enhancement | Priority | Difficulty | Impact |
|---|-------------|----------|------------|--------|
| 1 | Replace CustomPainter pizza with real artwork | 🔴 HIGH | Medium | Massive visual |
| 2 | Lottie animations (pizza loading, success) | 🔴 HIGH | Easy | Delight |
| 3 | Dark Mode | 🟡 MEDIUM | Medium | Professional |
| 4 | Favorites persistence | 🟡 MEDIUM | Easy | Feature |
| 5 | Better pizza card with real image assets | 🔴 HIGH | Medium | Visual |
| 6 | Animated bottom navigation transitions | 🟡 MEDIUM | Easy | Polish |
| 7 | Google Maps delivery tracking | 🟠 LOW | Hard | Feature |
| 8 | Push notifications | 🟠 LOW | Hard | Feature |
| 9 | Search screen | 🟡 MEDIUM | Medium | Feature |
| 10 | Real Firebase backend | 🟠 LOW | Hard | Production |
| 11 | Haptic feedback on interactions | 🟡 MEDIUM | Easy | Feel |
| 12 | Animated hero between list and detail | 🟡 MEDIUM | Easy | Transition |
| 13 | Pizza 360° parallax on tilt | 🟠 LOW | Hard | Wow factor |
| 14 | Checkout address map picker | 🟠 LOW | Hard | UX |

---

## #1 — Replace Pizza CustomPainter with Real Artwork ⭐ MOST WANTED

### Current Problem
The pizza is drawn using raw `Canvas` API in `pizza_illustration.dart`. This produces a simplistic,
geometric-looking pizza that doesn't match the premium MARIO brand.

### Recommended Solution: SVG Assets via `flutter_svg`

**Step 1 — Add dependency**
```yaml
# pubspec.yaml
dependencies:
  flutter_svg: ^2.0.10+1
```

**Step 2 — Get SVG pizza assets**

Option A: Download from [unDraw](https://undraw.co), [Humaaans](https://www.humaaans.com), or commission on [Fiverr](https://fiverr.com).

Option B: Free SVG pizza resources:
- https://www.svgrepo.com/collection/food-flat-icons/
- https://icons8.com/illustrations/style--pizza

Option C: Use Flutter's `CustomPainter` with much higher-quality path data (Figma export).

**Step 3 — Asset structure**
```
assets/
├── pizzas/
│   ├── margherita.svg
│   ├── pepperoni.svg
│   ├── four_cheese.svg
│   ├── spicy_diavola.svg
│   ├── veggie_garden.svg
│   ├── bbq_chicken.svg
│   ├── mushroom_truffle.svg
│   └── basil_special.svg
└── icons/
    ├── pepperoni_topping.svg
    ├── mushroom_topping.svg
    └── basil_topping.svg
```

**Step 4 — Replace `PizzaIllustration` widget**
```dart
// NEW: pizza_illustration.dart
class PizzaIllustration extends StatelessWidget {
  final String imageIdentifier;  // e.g. 'margherita'
  final double size;

  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/pizzas/$imageIdentifier.svg',
      width: size,
      height: size,
      placeholderBuilder: (_) => const PizzaPlaceholder(), // fallback
    );
  }
}
```

**Step 5 — Register assets in pubspec.yaml**
```yaml
flutter:
  assets:
    - assets/pizzas/
    - assets/icons/
```

### Alternative: Lottie Pizza Animations
Instead of static SVG, use **Lottie JSON animations** (from [LottieFiles.com](https://lottiefiles.com)):
- Search for "pizza" → download `.json` file
- Use `lottie: ^3.0.0` package

```dart
import 'package:lottie/lottie.dart';

class PizzaIllustration extends StatelessWidget {
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/pizza_rotating.json',
      width: size,
      height: size,
      repeat: true,
      animate: true,
    );
  }
}
```

Free Lottie pizza files:
- https://lottiefiles.com/search?q=pizza

---

## #2 — Lottie Loading & Success Animations

### Current Problem
- Loading uses a rotating 🍕 emoji (charming but low-fidelity)
- Checkout success has no celebration animation
- Order tracking page has no visual delight

### Recommended Implementation

**Files to get from LottieFiles.com:**
- `pizza_loading.json` — spinning pizza dough animation
- `order_success.json` — celebration/checkmark animation
- `delivery_scooter.json` — animated delivery scooter
- `chef_cooking.json` — chef cooking animation

**Update `MarioLoader`:**
```dart
class MarioLoader extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(
      children: [
        Lottie.asset(
          'assets/lottie/pizza_loading.json',
          width: 120,
          height: 120,
        ),
        Text(label, style: AppTypography.labelLarge),
      ],
    );
  }
}
```

**Add to CheckoutScreen after success:**
```dart
// In BlocListener when CheckoutStatus.success:
showDialog(
  context: context,
  builder: (_) => Dialog(
    child: Column(children: [
      Lottie.asset('assets/lottie/order_success.json', repeat: false),
      Text('Order Placed! 🎉'),
    ]),
  ),
);
```

---

## #3 — Dark Mode

### Approach
1. Add `AppColors.darkTheme` with dark variants
2. Create `AppTheme.darkTheme` with `Brightness.dark`
3. Use `ThemeMode` controlled by a `ThemeBloc` or simple `ValueNotifier`
4. Persist preference with `shared_preferences`

**Key dark colors:**
```dart
class AppColorsDark {
  static const Color background   = Color(0xFF1A1210); // Very dark warm brown
  static const Color surface      = Color(0xFF241A17); // Card bg
  static const Color surfaceHigh  = Color(0xFF2E2219); // Elevated card
  static const Color dark         = Color(0xFFFFF9F0); // Text (inverted)
  static const Color grey         = Color(0xFF8E8E93);
  // Primary, secondary, etc. stay the same
}
```

---

## #4 — Favorites Persistence

### Current State
`FavoritesScreen` shows empty state only — no add/remove logic.

### Implementation Plan

**1. Add to `PizzaEntity`:**
```dart
// No change needed — favorites stored separately
```

**2. Create `FavoritesRepository`:**
```dart
abstract class FavoritesRepositoryBase {
  Future<List<String>> getFavoriteIds();
  Future<void> addFavorite(String pizzaId);
  Future<void> removeFavorite(String pizzaId);
}

class LocalFavoritesRepository implements FavoritesRepositoryBase {
  // Use shared_preferences to persist favorite pizza IDs
}
```

**3. Create `FavoritesBloc`:**
```dart
class FavoritesCubit extends Cubit<List<String>> {
  FavoritesCubit(this._repo) : super([]);
  final FavoritesRepositoryBase _repo;

  Future<void> toggle(String pizzaId) async {
    final ids = List<String>.from(state);
    if (ids.contains(pizzaId)) {
      ids.remove(pizzaId);
    } else {
      ids.add(pizzaId);
    }
    emit(ids);
    await _repo.addFavorite(pizzaId); // or remove
  }
}
```

**4. Update heart icon in `PizzaDetailsScreen`:**
```dart
BlocBuilder<FavoritesCubit, List<String>>(
  builder: (context, ids) {
    final isFav = ids.contains(pizza.id);
    return IconButton(
      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
      color: AppColors.primary,
      onPressed: () => context.read<FavoritesCubit>().toggle(pizza.id),
    );
  },
)
```

---

## #5 — Better Pizza Cards

### Current Problem
Cards use `PizzaIllustration` (CustomPainter) which looks geometric.

### Improvements

**Option A: SVG card thumbnails (links with #1)**
Same SVG assets, displayed in card context.

**Option B: Add visual polish to existing cards**
- Add gradient overlay at bottom of illustration area
- Add "POPULAR" or "SPICY 🌶️" badge on specific pizzas
- Animate card appearance with `AnimatedOpacity` on first scroll into view
- Use `InkWell` instead of `GestureDetector` for proper ripple effect
- Add a `shimmer` placeholder while `PizzaIllustration` loads

**Option C: Use `CachedNetworkImage`**
If you have a backend serving pizza images:
```yaml
dependencies:
  cached_network_image: ^3.3.1
```

---

## #6 — Animated Bottom Navigation

### Current State
`MarioBottomNav` uses a custom drawn nav bar. Tab switching has no transition animation.

### Enhancement: Sliding indicator + icon pop

```dart
// Add AnimatedPositioned slider bar under active icon
// Add ScaleTransition when icon becomes active
// Add micro-bounce on tap (forward + reverse)
```

**PageView approach:** Wrap the shell content in a `PageView` with custom `PageController`
so tab transitions slide horizontally instead of hard-cutting.

---

## #11 — Haptic Feedback

### Add to every important interaction

```dart
import 'package:flutter/services.dart';

// Light tap → most buttons
HapticFeedback.lightImpact();

// Add to cart → medium
HapticFeedback.mediumImpact();

// Order placed → heavy
HapticFeedback.heavyImpact();

// Success notification → selection
HapticFeedback.selectionClick();
```

**Files to update:**
- `mario_button.dart` → `_onTapDown`
- `pizza_card.dart` → `_handleAddTap`
- `quantity_stepper.dart` → `_buildButton onPressed`
- `checkout_screen.dart` → on submit success

---

## #12 — Hero Transition Enhancement

### Current State
`Hero` widget is set up with tag `'pizza_hero_${pizza.id}'` in `PizzaCard` and `PizzaDetailsScreen`.

### Problem
`PizzaIllustration` renders identically in both places (same canvas drawing), so the Hero
transition works but shows no visual difference between list and detail sizes.

### Fix
When using SVG assets (#1), the Hero transition will look spectacular:
- Card: small 105px SVG thumbnail
- Hero transition: smooth scale-up to 240px
- Detail: full 240px SVG illustration on cream background

---

## #9 — Search Screen

### Implementation Plan

**Route:** Add `/search` inside ShellRoute

**Screen:** `SearchScreen`
```
SearchScreen
├── Search TextField (autofocus on open)
├── Recent searches (from SharedPreferences)
├── Live results (filter from GetPizzaBloc.state.pizzas)
│   └── PizzaCard (in list layout, not horizontal scroll)
└── Empty state if no matches
```

**BLoC:** Add `SearchCubit` with:
```dart
class SearchCubit extends Cubit<List<PizzaEntity>> {
  SearchCubit(this._allPizzas) : super([]);
  final List<PizzaEntity> _allPizzas;

  void search(String query) {
    if (query.isEmpty) { emit([]); return; }
    emit(_allPizzas.where((p) =>
      p.name.toLowerCase().contains(query.toLowerCase()) ||
      p.ingredients.any((i) => i.toLowerCase().contains(query.toLowerCase()))
    ).toList());
  }
}
```

---

## Future Ideas (Low Priority)

### Pizza Builder Preview (Real-time)
- The `PizzaCustomizationScreen` already updates `PizzaIllustration` in real-time
- With SVG assets, show ingredient SVG layering on the pizza illustration as you toggle them

### Loyalty Points System
- Add `loyaltyPoints` to `UserEntity`
- Award 10 points per $1 spent
- Redeem for discounts

### Order Scheduling
- Add `scheduledDelivery: DateTime?` to checkout
- Show time picker in `CheckoutScreen`

### Rating & Review System
- After delivery, prompt user to rate
- Display average rating on `PizzaCard`

### Referral Code System
- Each user gets a unique referral code
- Share via `share_plus` package
