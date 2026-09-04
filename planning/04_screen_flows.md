# 04 — Screen Flows & Navigation

## Navigation Flow Diagram

```mermaid
flowchart TD
    Start([App Launch]) --> Auth{Auth Status?}
    Auth -->|unknown| Loading[Wait for stream]
    Auth -->|unauthenticated| Welcome[WelcomeScreen\n/welcome]
    Auth -->|authenticated| Home[HomeScreen\n/home]

    Welcome -->|Explore Menu| Home
    Welcome -->|I have an account| SignIn[SignInScreen\n/signin]
    SignIn -->|success| Home
    SignIn -->|no account| SignUp[SignUpScreen\n/signup]
    SignUp -->|success| Home

    Home -->|pizza card tap| Details[PizzaDetailsScreen\n/pizza/:id]
    Home -->|quick add button| CartBadge[Cart badge +1]
    Home -->|Build Your Own| Customize[PizzaCustomizationScreen\n/pizza/:id/customize]
    Home -->|bottom nav: Cart| Cart[CartScreen\n/cart]
    Home -->|bottom nav: Orders| Orders[OrdersScreen\n/orders]
    Home -->|bottom nav: Favorites| Favorites[FavoritesScreen\n/favorites]
    Home -->|avatar tap| Profile[ProfileScreen\n/profile]

    Details -->|Add to Cart| Cart
    Details -->|Customize| Customize
    Customize -->|Add to Cart| Cart

    Cart -->|Proceed to Checkout| Checkout[CheckoutScreen\n/checkout]
    Checkout -->|Order Placed| Tracking[OrderTrackingScreen\n/orders/:id]
    Orders -->|Track Order| Tracking

    Profile -->|Sign Out| Welcome
```

---

## Screen State Machines

### WelcomeScreen — Animation Sequence

```mermaid
stateDiagram-v2
    [*] --> Init: Screen created
    Init --> Animating: _entranceController.forward()
    Animating --> FloatingLoop: _floatController.repeat(reverse:true)
    FloatingLoop --> CTAVisible: 400ms delay → _ctaController.forward()
    CTAVisible --> Idle: All animations settled
    Idle --> [*]: User taps CTA
```

### HomeScreen — Load Sequence

```mermaid
stateDiagram-v2
    [*] --> Init: initState()
    Init --> LoadingMenu: GetPizzaBloc.add(GetPizzasRequested)
    LoadingMenu --> ShowShimmer: GetPizzaStatus.loading
    ShowShimmer --> ShowPizzas: GetPizzaStatus.success
    ShowShimmer --> ShowError: GetPizzaStatus.failure
    ShowError --> LoadingMenu: retry tap
    ShowPizzas --> Idle: All cards rendered
    Idle --> FilteredPizzas: Category chip tapped
    FilteredPizzas --> Idle: All/different category
```

### CartBloc — State Machine

```mermaid
stateDiagram-v2
    [*] --> initial
    initial --> loading: CartStarted event
    loading --> success: _CartUpdated (stream emit)
    loading --> failure: stream error
    success --> success: CartItemAdded / Removed / Updated
    success --> success: CartPromoApplied (valid)
    success --> failure: CartPromoApplied (invalid code)
    failure --> loading: CartStarted retry
    success --> success: CartCleared → empty cart
```

### CheckoutBloc — Order Flow

```mermaid
stateDiagram-v2
    [*] --> initial
    initial --> loading: CheckoutStarted
    loading --> ready: cart loaded
    ready --> ready: AddressChanged
    ready --> ready: PaymentChanged
    ready --> submitting: CheckoutSubmitted (isValid = true)
    submitting --> success: order placed
    submitting --> failure: network/mock error
    success --> [*]: navigate to /orders/:id
```

### Order Tracking — Status Progression (Mock)

```mermaid
stateDiagram-v2
    [*] --> confirmed: Order placed
    confirmed --> preparing: after 15s (mock timer)
    preparing --> baking: after 15s
    baking --> outForDelivery: after 15s
    outForDelivery --> delivered: after 15s
    delivered --> [*]: Order complete
```

---

## Screen Component Breakdown

### HomeScreen

```
HomeScreen
├── SafeArea
│   └── RefreshIndicator
│       └── SingleChildScrollView
│           ├── Header (location + avatar) ← animated slide-in
│           ├── Greeting text ← dynamic by time of day
│           ├── _HeroBanner ← rotating pizza + promo text
│           ├── Category chips (horizontal ListView)
│           ├── "Popular Right Now" section header
│           ├── Pizza horizontal ListView
│           │   └── PizzaCard × N (staggered TweenAnimationBuilder)
│           └── _BuildYourOwnBanner ← press scale animation
```

### PizzaDetailsScreen

```
PizzaDetailsScreen
├── AppBar (floating back + favorite buttons)
└── Column
    ├── Expanded → SingleChildScrollView
    │   ├── Container (cream bg) → Hero → PizzaIllustration
    │   └── Padding (content) ← slide+fade animation
    │       ├── Rating + Category row
    │       ├── Pizza name (displayMedium)
    │       ├── Description
    │       ├── Nutrition badges row (4 items)
    │       ├── Ingredients Wrap (Chip × N)
    │       └── OutlinedButton → Customize
    └── Sticky bottom bar
        ├── Price column
        └── MarioButton ("Add to Cart" / "✓ Added!")
```

### CartScreen

```
CartScreen
├── AppBar (title + clear all icon)
└── BlocBuilder~CartBloc~
    ├── (empty) → MarioEmptyState → Browse Pizzas
    └── (has items) → Column
        ├── Expanded → ListView
        │   └── CartItem × N ← TweenAnimationBuilder stagger
        │       ├── PizzaIllustration (size: 70)
        │       ├── Name + customization summary
        │       ├── Price
        │       └── QuantityStepper
        └── Sticky bottom panel
            ├── Promo code input
            ├── Price breakdown (subtotal, delivery, discount, total)
            └── MarioButton → /checkout (context.push)
```

---

## Bottom Navigation Tabs

| Index | Label | Icon | Route |
|-------|-------|------|-------|
| 0 | Home | home_rounded | `/home` |
| 1 | Explore | explore_rounded | `/explore` |
| 2 | Orders | receipt_long_rounded | `/orders` |
| 3 | Favorites | favorite_rounded | `/favorites` |
| 4 | Cart | shopping_bag_rounded | `/cart` (has badge) |
