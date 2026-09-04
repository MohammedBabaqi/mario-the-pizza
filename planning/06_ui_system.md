# 06 — UI System (Design Tokens + Components)

## Color Palette

```dart
class AppColors {
  // BRAND
  static const Color primary       = Color(0xFFE63946); // Tomato Red
  static const Color secondary     = Color(0xFF2A9D8F); // Basil Green
  static const Color cheese        = Color(0xFFF4A261); // Orange Cheese
  static const Color goldenCheese  = Color(0xFFE9C46A); // Golden Yellow
  static const Color crust         = Color(0xFFD4A373); // Warm Crust Brown

  // NEUTRALS
  static const Color cream         = Color(0xFFFFF7E8); // Warm Cream
  static const Color background    = Color(0xFFFFF9F0); // Main bg
  static const Color dark          = Color(0xFF241A17); // Near-black text
  static const Color darkSecondary = Color(0xFF3D2E29); // Subtitle
  static const Color grey          = Color(0xFF8E8E93); // Muted
  static const Color lightGrey     = Color(0xFFF2F2F7); // Dividers
  static const Color white         = Color(0xFFFFFFFF);

  // SEMANTIC
  static const Color success       = Color(0xFF34C759);
  static const Color error         = Color(0xFFFF3B30);
  static const Color warning       = Color(0xFFFFCC00);
  static const Color info          = Color(0xFF007AFF);

  // SURFACE
  static const Color cardBackground         = Color(0xFFFFFFFF);
  static const Color cardBackgroundElevated = Color(0xFFFFFCF5);
  static const Color shimmerBase            = Color(0xFFF5F0E8);
  static const Color shimmerHighlight       = Color(0xFFFFFAF2);
}
```

### Visual Color Swatch

| Token | Hex | Purpose |
|-------|-----|---------|
| `primary` | `#E63946` | CTAs, prices, nav active |
| `secondary` | `#2A9D8F` | Success states, badges |
| `cheese` | `#F4A261` | Decorative, pizza art |
| `goldenCheese` | `#E9C46A` | Rating stars, highlights |
| `cream` | `#FFF7E8` | Category chips, cards |
| `background` | `#FFF9F0` | Scaffold background |
| `dark` | `#241A17` | Primary text |
| `grey` | `#8E8E93` | Placeholder text |

---

## Typography Scale

Font: **Outfit** (Google Fonts) for all display/heading/label text
System font for body text (performance optimization)

```
Display Large   → Outfit  40px  700  -1.5 letterSpacing  [Hero headlines]
Display Medium  → Outfit  32px  700  -1.0               [Screen titles]
Display Small   → Outfit  24px  600  -0.5               [Section titles]

Headline Large  → Outfit  22px  600                     [Card headers]
Headline Medium → Outfit  20px  600                     [AppBar title]
Headline Small  → Outfit  18px  600                     [Section headers]

Title Large     → Outfit  18px  500                     [List items]
Title Medium    → System  16px  500                     [Subtitles]
Title Small     → System  14px  500

Body Large      → System  16px  400  1.5 lineHeight      [Descriptions]
Body Medium     → System  14px  400  1.5
Body Small      → System  12px  400  1.5  grey color     [Captions]

Label Large     → Outfit  14px  600  0.2 letterSpacing   [Buttons]
Label Medium    → System  12px  500  0.2
Label Small     → System  11px  500  0.3  grey color

price           → Outfit  18px  700  primary color       [Price tags]
priceSmall      → Outfit  14px  600  primary color
brand           → Outfit  28px  800  primary color  2.0 spacing  [Logo]
```

---

## Spacing System

```dart
class AppSpacing {
  static const double xxs          = 4.0;
  static const double xs           = 8.0;
  static const double sm           = 12.0;
  static const double md           = 16.0;
  static const double lg           = 20.0;
  static const double xl           = 24.0;
  static const double xxl          = 32.0;
  static const double xxxl         = 48.0;
  static const double screenPadding = 20.0;  // All screen h-padding
}
```

---

## Border Radius System

```dart
class AppRadius {
  static const double xs   = 6.0;
  static const double sm   = 10.0;
  static const double md   = 14.0;
  static const double lg   = 20.0;
  static const double xl   = 28.0;
  static const double full = 100.0;

  static const double bottomSheet = 28.0;

  // Named border radii (BorderRadius objects)
  static BorderRadius get cardBorderRadius   → BorderRadius.circular(16)
  static BorderRadius get buttonBorderRadius → BorderRadius.circular(14)
  static BorderRadius get chipBorderRadius   → BorderRadius.circular(20)
  static BorderRadius get textFieldBorderRadius → BorderRadius.circular(12)
}
```

---

## Animation Duration Tokens

```dart
class AppDurations {
  static const Duration micro   = Duration(milliseconds: 100);  // Press feedback
  static const Duration fast    = Duration(milliseconds: 200);  // Chips, toggles
  static const Duration normal  = Duration(milliseconds: 300);  // Cards, panels
  static const Duration slow    = Duration(milliseconds: 500);  // Page entrances
  static const Duration xslow  = Duration(milliseconds: 800);  // Splash, heroes
}
```

---

## Component Catalog

### MarioButton
**Location:** `lib/core/widgets/mario_button.dart`

```dart
MarioButton(
  label: 'Add to Cart',
  icon: Icons.shopping_bag_outlined,    // optional prefix icon
  isLoading: false,
  backgroundColor: AppColors.primary,   // customizable
  textColor: AppColors.white,
  height: 54,
  onPressed: () { ... },
)
```

**Behavior:**
- `GestureDetector` → `onTapDown` triggers `AnimationController.forward()` (scale 1.0 → 0.96)
- `onTapUp` → reverse
- When `onPressed == null` → grey disabled appearance (no shadow)
- When `isLoading == true` → `CircularProgressIndicator` replaces text

---

### PizzaIllustration
**Location:** `lib/core/widgets/pizza_illustration.dart`

```dart
PizzaIllustration(
  size: 200,              // width = height
  crust: 'classic',       // 'classic' | 'cheesy' | 'stuffed'
  sauce: 'tomato',        // 'tomato' | 'spicy' | 'creamy'
  toppings: ['Pepperoni', 'Basil'],  // matched case-insensitively
  animateToppings: true,  // currently unused, reserved
)
```

**Layers drawn by `_PizzaPainter`:**
1. Drop shadow (blurred circle)
2. Crust circle (color varies by crust type)
3. Crust rim stroke
4. Sauce circle (color varies by sauce type)
5. Cheese base (uniform orange circle)
6. Golden cheese spots (5 circles)
7. Dynamic toppings based on ingredients list:
   - Pepperoni → dark red circles with highlight
   - Mushrooms → arc cap + rect stem
   - Olives → black circle with golden hole
   - Basil → leaf bezier paths
   - Bell Peppers → green stroke curves

> ⚠️ **Known limitation:** This is drawn with raw `Canvas` API — it looks geometric
> and simplistic. See `07_enhancements.md` for the SVG/Lottie replacement plan.

---

### PizzaCard
**Location:** `lib/core/widgets/pizza_card.dart`

```dart
PizzaCard(
  pizza: pizzaEntity,
  onTap: () => context.push('/pizza/${pizza.id}'),
  onQuickAdd: () { /* dispatch CartItemAdded */ },
)
```

**Layout (220px wide card):**
```
┌──────────────────────────┐
│  PizzaIllustration(105)  │  ← Hero tag: 'pizza_hero_${pizza.id}'
│                   ⭐4.8  │  ← Rating badge (top-right)
├──────────────────────────┤
│  Pizza Name (bold)       │
│  ingredient1, ingredient2│  ← max 2 lines
│                          │
│  $10.99        [  +  ]   │  ← Quick add button with scale animation
└──────────────────────────┘
```

---

### QuantityStepper

```dart
QuantityStepper(
  value: item.quantity,
  onChanged: (newQty) { /* CartItemQuantityUpdated */ },
  min: 1,   // won't go below 1 (use remove button for 0)
  max: 10,
)
```
Uses `AnimatedSwitcher` (scale transition) for the count text.

---

### OrderTimeline

```dart
OrderTimeline(steps: order.trackingSteps)
```

Each step shows:
- `AnimatedContainer` circle: **red** if active, **green** if completed, **grey** if pending
- Active step has glow `BoxShadow`
- Connecting line: green when step completed, grey otherwise

---

### MarioLoader

```dart
MarioLoader(size: 64, label: 'Baking magic... 🍕')
```

A 🍕 emoji that spins continuously with a 2-second `AnimationController.repeat()`.

---

### AbstractBlob + FloatingIngredientParticle

```dart
// Decorative blob shape (organic silhouette)
AbstractBlob(width: 280, height: 280, color: AppColors.cream, child: ...)

// Floating emoji particle with rotation
FloatingIngredientParticle(
  emoji: '🌿',
  size: 28,
  offset: Offset(10, -5),
  rotation: -0.4,
)
```

---

## Material 3 Theme Configuration

The app uses `ThemeData(useMaterial3: true)` with:
- All component themes overridden (chips, cards, buttons, inputs, snackbar, etc.)
- `CupertinoPageTransitionsBuilder` on all platforms for smooth iOS-style page transitions
- AppBar: `elevation: 0`, `scrolledUnderElevation: 0` (no shadow on scroll)
- Chips: `selectedColor: AppColors.primary` (with `labelStyle` → white)
- SnackBar: `floating`, dark background, rounded corners

---

## Shadow System

```dart
class AppShadows {
  // Standard card shadow
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x08000000), blurRadius: 4,  offset: Offset(0, 1)),
  ];

  // Elevated card (detail screens)
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // Bottom navigation / sticky bottom bars
  static const List<BoxShadow> nav = [
    BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, -4)),
  ];
}
```
