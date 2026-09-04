# 08 — Copy-Paste ChatGPT Prompts for Improvements

> Use these pre-formatted prompts to ask ChatGPT or any LLM for specific improvements to the MARIO app.
> Copy the entire box for the prompt you want, paste it into ChatGPT, and get production-ready code.

---

## 📋 Prompt 1: Replace Pizza Vector Drawing with SVG Artwork

```markdown
I am building a premium Flutter pizza delivery application called **MARIO**.
Currently, pizzas are rendered using a simplistic `CustomPainter` in `lib/core/widgets/pizza_illustration.dart`.
I want to replace this with high-quality SVG vector illustrations using the `flutter_svg` package.

Here is the context of how `PizzaIllustration` is currently used:
- It receives parameters: `double size`, `String crust`, `String sauce`, `List<String> toppings`, `bool animateToppings`.
- It's used inside `PizzaCard` (size: 105), `PizzaDetailsScreen` (size: 240, hero animation), `CartScreen` (size: 70), and `WelcomeScreen` (size: 230, hero animation).

Please provide:
1. Updated `pubspec.yaml` snippet adding `flutter_svg: ^2.0.10+1` and declaring asset folders `assets/pizzas/` and `assets/toppings/`.
2. A complete rewritten `PizzaIllustration` widget that:
   - Loads SVG files dynamically based on a pizza `imageIdentifier` or fallback pizza name.
   - Smoothly handles loading state / missing SVG fallback using a placeholder.
   - Retains the shadow/glow effect behind the SVG artwork.
   - Supports size customization and rotatable wrapper for onboarding animations.
3. Instructions on where to put SVG assets and recommended free SVG icon libraries suitable for pizza/food apps.
```

---

## 📋 Prompt 2: Add Lottie Animations for Loading, Success & Empty States

```markdown
I am building a Flutter pizza delivery app called **MARIO**.
I want to elevate the UX by integrating Lottie JSON animations (`lottie` package) for:
1. Loading indicator (replacing basic spinner with spinning pizza dough/baking animation).
2. Order Success modal/screen after checkout (confetti/checkmark/celebration).
3. Empty cart and empty orders states.
4. Order tracking delivery progress (animated delivery scooter/driver).

Please provide:
1. `pubspec.yaml` updates for `lottie: ^3.0.0`.
2. Rewritten `MarioLoader` widget using Lottie asset with smooth fallback if asset fails to load.
3. A reusable `LottieSuccessDialog` or bottom sheet with celebration feedback when an order is placed.
4. Updated `MarioEmptyState` widget supporting optional Lottie animation path alongside emoji fallback.
5. Recommended free Lottie files from LottieFiles for food, pizza, delivery, and success states.
```

---

## 📋 Prompt 3: Implement Full Dark Mode Theme Support

```markdown
I have a Flutter application called **MARIO** with a central design token setup in `lib/app/theme/`.
Currently, it only supports light mode. I want to add complete Dark Mode support without breaking Clean Architecture or BLoC patterns.

Here is the current theme setup:
- `AppColors`: Primary (#E63946), Secondary (#2A9D8F), Cream (#FFF7E8), Background (#FFF9F0), Dark (#241A17).
- `AppTypography`: Google Fonts (Outfit) + default body fonts.
- `AppTheme`: Returns `ThemeData.lightTheme`.

Please provide:
1. Updated `AppColors` adding dark palette equivalents (`darkBackground`, `darkSurface`, `darkCard`, `darkText`, etc.).
2. Complete `AppTheme.darkTheme` method matching `AppTheme.lightTheme` structure with dark tokens.
3. A `ThemeCubit` (or `ThemeBloc`) to manage `ThemeMode` (light, dark, system) with `shared_preferences` persistence.
4. Code to wrap `MaterialApp.router` with the theme state, including standard theme toggle button widget for `ProfileScreen`.
```

---

## 📋 Prompt 4: Build Local Favorites System with Persistence

```markdown
In my Flutter pizza delivery app **MARIO**, `FavoritesScreen` is currently a shell with an empty state, and the heart icon on `PizzaDetailsScreen` is a visual placeholder.

I want to implement a complete Favorites feature:
1. Users can tap the heart icon on any pizza (on `PizzaCard` or `PizzaDetailsScreen`) to toggle favorite status.
2. Favorites must persist locally using `shared_preferences`.
3. `FavoritesScreen` should display the list of favorited `PizzaEntity` objects fetched from `GetPizzaBloc` / `PizzaRepositoryBase`.
4. Tapping a favorite pizza navigates to details screen; removing it updates the UI immediately with smooth deletion animation.

Please write:
1. `FavoritesRepositoryBase` and `SharedPreferencesFavoritesRepository` in Dart.
2. `FavoritesCubit` (state: `Set<String>` of pizza IDs).
3. Integration snippets for `PizzaDetailsScreen` heart button and `FavoritesScreen` grid/list layout.
```

---

## 📋 Prompt 5: Implement Interactive Pizza Builder Layering

```markdown
In my Flutter app **MARIO**, users can customize their pizza on `PizzaCustomizationScreen` by choosing size (Small, Medium, Large), crust (Classic, Thin, Cheesy, Stuffed), sauce (Tomato, Spicy, Creamy), and extra toppings (Pepperoni, Mushrooms, Olives, Basil, Extra Cheese).

I want an interactive visual preview widget (`InteractivePizzaBuilder`) where:
- Base pizza crust changes shape/color based on crust selection.
- Sauce layer changes color depending on selected sauce (red tomato, orange spicy, white creamy).
- Topping icons/SVGs are dynamically placed on top of the pizza canvas when checked/unchecked.
- Toggling a topping animates that topping dropping onto the pizza (scale/fade/bounce animation).

Please write a clean, self-contained Flutter widget `InteractivePizzaBuilder` using `Stack`, `AnimatedPositioned`, `AnimatedOpacity`, or `CustomPainter` that reacts to `PizzaCustomizationState`.
```

---

## 📋 Prompt 6: Add Haptic Feedback & Audio Sound Effects

```markdown
I want to add tactile and auditory delight to my Flutter app **MARIO**:
1. Haptic feedback on button taps (light for standard taps, medium for quick add, heavy for order submission, selection for chip switches).
2. Subtle audio sound effects (optional toggle) when adding item to cart (pop/ding sound) and placing an order (celebration sound).

Please provide:
1. A clean helper class `MarioFeedback` wrapping `HapticFeedback` and `audioplayers` package.
2. Snippets showing where to invoke `MarioFeedback.light()`, `MarioFeedback.addToCart()`, and `MarioFeedback.orderSuccess()`.
3. Best practices to avoid latency or audio blocking on iOS and Android.
```

---

## 📋 Prompt 7: Add Search & Filter Screen

```markdown
I want to add a dedicated Search & Filtering experience to my Flutter pizza app **MARIO**.

Requirements:
- Search bar with instant real-time filtering by pizza name, ingredient, or category.
- Recent search queries stored locally (max 5 items, clearable).
- Price range filter slider ($5 - $20) and minimum rating filter (3.0+ stars).
- Sort options: Popularity, Price (Low to High), Price (High to Low), Rating.
- Clean empty search result state with quick suggestions ("Try Pepperoni", "Try Veggie").

Please provide:
1. `SearchCubit` managing search query, filters, sorting, and filtered list result.
2. `SearchScreen` widget with SearchBar, Filter modal/bottom sheet, and result grid.
3. GoRouter integration as a route `/search`.
```
