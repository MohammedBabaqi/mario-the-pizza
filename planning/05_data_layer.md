# 05 — Data Layer

## Repository Pattern Overview

Every data operation goes through a **repository interface** (abstract class). The UI and BLoCs only
know about the interface — they never import a concrete implementation.

```
BLoC/Cubit
   └── depends on → RepositoryBase (abstract)
                          └── implemented by
                                ├── MockDataSource (no Firebase needed)
                                └── FirebaseDataSource (production)
```

Switching from Mock to Firebase requires only changing **one line** in `service_locator.dart`:

```dart
// BEFORE (mock)
sl.registerFactory<UserRepositoryBase>(() => MockUserDataSource());

// AFTER (firebase)
sl.registerFactory<UserRepositoryBase>(() => FirebaseUserDataSource(
  firebaseAuth: FirebaseAuth.instance,
  firestore: FirebaseFirestore.instance,
));
```

---

## Entity Relationships

```mermaid
erDiagram
    USER {
        string uid PK
        string email
        string displayName
        datetime createdAt
        string defaultAddress
        string photoUrl
    }

    PIZZA {
        string id PK
        string name
        string description
        float price
        float rating
        int calories
        int protein
        int fat
        int carbs
        string category FK
        string imageIdentifier
        bool isPopular
        bool isRecommended
    }

    CATEGORY {
        string id PK
        string name
        string emoji
        int sortOrder
    }

    INGREDIENT {
        string id PK
        string name
        string type
        float priceModifier
        int calorieModifier
        string emoji
    }

    CART_ITEM {
        string id PK
        string pizzaId FK
        int quantity
        string size
        string crust
        string sauce
        string extraToppings
    }

    CART {
        float deliveryFee
        float discount
        string promoCode
    }

    ORDER {
        string id PK
        string userId FK
        string status
        float subtotal
        float deliveryFee
        float discount
        float total
        string deliveryAddress
        string paymentMethod
        datetime createdAt
        datetime estimatedDelivery
    }

    ORDER_STEP {
        string status
        datetime completedAt
        bool isActive
    }

    USER ||--o{ ORDER : places
    ORDER ||--|{ CART_ITEM : contains
    ORDER ||--|{ ORDER_STEP : tracks
    CART ||--|{ CART_ITEM : has
    CART_ITEM }|--|| PIZZA : is
    PIZZA }|--|| CATEGORY : belongs_to
```

---

## Mock Data Seed

### MockUserDataSource
- Pre-loaded demo user at startup: `demo@mario.com / Password123`
- **Auto signs in** in development — user is authenticated immediately
- Any email/password combo creates a new mock user (no validation)

### MockPizzaDataSource
- 8 hardcoded `PizzaEntity` objects (const, no I/O)
- Simulates API latency with `Future.delayed`:
  - `getPizzas()`: 600ms
  - `getPizzaById()`: 300ms
  - `getPizzasByCategory()`: 400ms
  - `getCategories()`: 200ms

### CartDataSource (always in-memory, no mock/real split)
- Backed by a `StreamController<CartEntity>.broadcast()`
- Cart state lives only in RAM — clears on app restart
- Promo codes: `MARIO10`, `PIZZA5`, `FREESHIP`
- Free delivery when subtotal ≥ $25.00

### MockOrderDataSource
- Places orders as in-memory objects
- Auto-advances order status every ~15 seconds via a `Timer`
- Broadcasts status changes through individual `StreamController`s per orderId
- Returns live `Stream<OrderEntity>` for real-time tracking UI

---

## Data Flow: Complete Pizza Order

```mermaid
sequenceDiagram
    participant U as User
    participant CS as CartScreen
    participant CB as CartBloc
    participant CK as CheckoutScreen
    participant CHB as CheckoutBloc
    participant OR as OrderRepository
    participant OT as OrderTrackingScreen
    participant OTB as OrderTrackingBloc

    U->>CS: Tap "Proceed to Checkout"
    CS->>CK: context.push('/checkout')
    CK->>CHB: CheckoutStarted event
    CHB->>CB: cartRepository.currentCart (sync read)
    CHB-->>CK: emit(CheckoutState.ready)

    U->>CK: Fill address + payment → tap Submit
    CK->>CHB: CheckoutSubmitted(userId)
    CHB->>OR: placeOrder(cart, userId, address, payment)
    OR-->>CHB: OrderEntity (confirmed)
    CHB-->>CK: emit(CheckoutState.success)
    CK->>OT: context.go('/orders/:id')

    OT->>OTB: OrderTrackingStarted(orderId)
    OTB->>OR: watchOrder(orderId) → Stream
    OR-->>OTB: OrderEntity (confirmed)
    OTB-->>OT: emit(active, step=0)

    Note over OR: Timer fires after 15s
    OR-->>OTB: OrderEntity (preparing)
    OTB-->>OT: emit(active, step=1)

    Note over OR: Repeated until...
    OR-->>OTB: OrderEntity (delivered)
    OTB-->>OT: emit(completed)
```

---

## Code: Key Data Structures

### CartEntity computed properties
```dart
class CartEntity extends Equatable {
  final List<CartItemEntity> items;
  final double deliveryFee;   // default: $2.99
  final double discount;
  final String? promoCode;

  // Free delivery when subtotal >= $25
  double get effectiveDeliveryFee => subtotal >= 25.00 ? 0.0 : deliveryFee;

  // Grand total
  double get total => subtotal + effectiveDeliveryFee - discount;

  // Count including quantity multipliers
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
```

### CartItemEntity price calculation
```dart
double get itemTotal {
  final basePrice  = pizza.price;
  final sizeExtra  = size.priceModifier;    // 0 / 2.00 / 4.00
  final crustExtra = crust.priceModifier;   // 0 / 0 / 1.50 / 2.50
  final sauceExtra = sauce.priceModifier;   // 0 / 0.50 / 0.50
  final toppingsExtra = extraToppings.length * 1.00;  // $1 per topping
  return (basePrice + sizeExtra + crustExtra + sauceExtra + toppingsExtra) * quantity;
}
```

### OrderEntity progress tracking
```dart
// Index of current status in enum (0=confirmed, 4=delivered)
int get currentStepIndex => OrderStatus.values.indexOf(status);

// Progress bar fraction (0.0 → 1.0)
double get progress => (currentStepIndex + 1) / OrderStatus.values.length;

// Countdown timer
int get estimatedMinutesRemaining {
  if (estimatedDelivery == null) return 0;
  final remaining = estimatedDelivery!.difference(DateTime.now()).inMinutes;
  return remaining > 0 ? remaining : 0;
}
```

---

## Firestore Schema (Production — Not Yet Active)

```
/users/{uid}
  uid: string
  email: string
  displayName: string
  createdAt: timestamp
  defaultAddress: string?
  photoUrl: string?

/pizzas/{pizzaId}
  (all PizzaEntity fields)
  createdAt: timestamp

/orders/{orderId}
  userId: string (ref → /users/{uid})
  status: string (OrderStatus.name)
  items: array of CartItemEntity maps
  subtotal: number
  deliveryFee: number
  discount: number
  total: number
  deliveryAddress: string
  paymentMethod: string
  createdAt: timestamp
  estimatedDelivery: timestamp

/orders/{orderId}/trackingSteps/{stepId}
  status: string
  completedAt: timestamp?
  isActive: bool
```
