# 03 — Class UML Diagrams

> All diagrams use Mermaid syntax. Paste into any Mermaid renderer (e.g. mermaid.live, GitHub, Notion).

---

## 1. Domain Entities

```mermaid
classDiagram

class PizzaEntity {
  +String id
  +String name
  +String description
  +double price
  +double rating
  +int calories
  +int protein
  +int fat
  +int carbs
  +List~String~ ingredients
  +String category
  +String imageIdentifier
  +bool isPopular
  +bool isRecommended
  +copyWith() PizzaEntity
}

class CategoryEntity {
  +String id
  +String name
  +String emoji
  +int sortOrder
}

class IngredientEntity {
  +String id
  +String name
  +IngredientType type
  +double priceModifier
  +int calorieModifier
  +String emoji
}

class IngredientType {
  <<enumeration>>
  topping
  cheese
  sauce
  crust
}

IngredientEntity --> IngredientType
```

---

## 2. Cart Entities + Enums

```mermaid
classDiagram

class CartItemEntity {
  +String id
  +PizzaEntity pizza
  +int quantity
  +PizzaSize size
  +CrustType crust
  +SauceType sauce
  +List~String~ extraToppings
  +double itemTotal
  +String customizationSummary
  +copyWith() CartItemEntity
}

class CartEntity {
  +List~CartItemEntity~ items
  +double deliveryFee
  +double discount
  +String? promoCode
  +int itemCount
  +int uniqueItemCount
  +bool isEmpty
  +bool isNotEmpty
  +double subtotal
  +double effectiveDeliveryFee
  +double total
  +static CartEntity empty
  +copyWith() CartEntity
}

class PizzaSize {
  <<enumeration>>
  small [label, priceModifier]
  medium [label, priceModifier]
  large [label, priceModifier]
}

class CrustType {
  <<enumeration>>
  classic [label, priceModifier]
  thin [label, priceModifier]
  cheesy [label, priceModifier]
  stuffed [label, priceModifier]
}

class SauceType {
  <<enumeration>>
  tomato [label, priceModifier]
  spicy [label, priceModifier]
  creamy [label, priceModifier]
}

CartEntity "1" o-- "0..*" CartItemEntity
CartItemEntity --> PizzaSize
CartItemEntity --> CrustType
CartItemEntity --> SauceType
CartItemEntity --> PizzaEntity
```

---

## 3. Order Entities

```mermaid
classDiagram

class OrderEntity {
  +String id
  +String userId
  +List~CartItemEntity~ items
  +OrderStatus status
  +double subtotal
  +double deliveryFee
  +double discount
  +double total
  +String deliveryAddress
  +String paymentMethod
  +DateTime createdAt
  +DateTime? estimatedDelivery
  +List~OrderTrackingStep~ trackingSteps
  +int estimatedMinutesRemaining
  +int currentStepIndex
  +double progress
  +copyWith() OrderEntity
}

class OrderStatus {
  <<enumeration>>
  confirmed [label, emoji]
  preparing [label, emoji]
  baking [label, emoji]
  outForDelivery [label, emoji]
  delivered [label, emoji]
}

class OrderTrackingStep {
  +OrderStatus status
  +DateTime? completedAt
  +bool isActive
  +bool isCompleted
}

class UserEntity {
  +String uid
  +String email
  +String displayName
  +DateTime createdAt
  +String? defaultAddress
  +String? photoUrl
}

OrderEntity --> OrderStatus
OrderEntity "1" o-- "0..*" OrderTrackingStep
OrderEntity "1" o-- "0..*" CartItemEntity
OrderTrackingStep --> OrderStatus
```

---

## 4. Repository Interfaces

```mermaid
classDiagram

class UserRepositoryBase {
  <<abstract>>
  +Stream~UserEntity?~ currentUser
  +signIn(email, password) Future~UserEntity~
  +signUp(email, password, name) Future~UserEntity~
  +signOut() Future~void~
  +resetPassword(email) Future~void~
  +getUserData(uid) Future~UserEntity?~
  +updateUserData(user) Future~void~
}

class PizzaRepositoryBase {
  <<abstract>>
  +getPizzas() Future~List~PizzaEntity~~
  +getPizzaById(id) Future~PizzaEntity~
  +watchPizzas() Stream~List~PizzaEntity~~
  +getPizzasByCategory(categoryId) Future~List~PizzaEntity~~
  +getCategories() Future~List~CategoryEntity~~
  +getAvailableIngredients() Future~List~IngredientEntity~~
}

class CartRepositoryBase {
  <<abstract>>
  +Stream~CartEntity~ cartStream
  +CartEntity currentCart
  +addItem(item) Future~void~
  +removeItem(itemId) Future~void~
  +updateQuantity(itemId, quantity) Future~void~
  +clearCart() Future~void~
  +applyPromoCode(code) Future~void~
  +dispose() void
}

class OrderRepositoryBase {
  <<abstract>>
  +placeOrder(cart, userId, address, payment) Future~OrderEntity~
  +getOrders(userId) Future~List~OrderEntity~~
  +watchOrder(orderId) Stream~OrderEntity~
  +cancelOrder(orderId) Future~void~
}

class MockUserDataSource {
  -StreamController~UserEntity?~ _userController
  -UserEntity? _currentUser
  -Map _users
}

class MockPizzaDataSource {
  -static List~PizzaEntity~ _mockPizzas
  -static List~CategoryEntity~ _mockCategories
  -static List~IngredientEntity~ _mockIngredients
}

class CartDataSource {
  -StreamController~CartEntity~ _cartController
  -CartEntity _cart
}

class MockOrderDataSource {
  -List~OrderEntity~ _orders
  -Map~String, StreamController~ _orderControllers
}

UserRepositoryBase <|.. MockUserDataSource
PizzaRepositoryBase <|.. MockPizzaDataSource
CartRepositoryBase <|.. CartDataSource
OrderRepositoryBase <|.. MockOrderDataSource
```

---

## 5. BLoC / Cubit State Machines

### AuthenticationBloc

```mermaid
classDiagram

class AuthenticationBloc {
  +UserRepositoryBase userRepository
  -StreamSubscription _userSubscription
  +add(AuthStarted)
  +add(AuthUserChanged)
  +add(AuthSignOutRequested)
}

class AuthenticationEvent {
  <<abstract>>
}
class AuthStarted { }
class AuthUserChanged { +UserEntity? user }
class AuthSignOutRequested { }

class AuthenticationState {
  +AuthStatus status
  +UserEntity? user
  +AuthenticationState.unknown()
  +AuthenticationState.authenticated(user)
  +AuthenticationState.unauthenticated()
}

class AuthStatus {
  <<enumeration>>
  unknown
  authenticated
  unauthenticated
}

AuthenticationBloc --> AuthenticationState
AuthenticationBloc --> AuthenticationEvent
AuthenticationEvent <|-- AuthStarted
AuthenticationEvent <|-- AuthUserChanged
AuthenticationEvent <|-- AuthSignOutRequested
AuthenticationState --> AuthStatus
```

---

### GetPizzaBloc

```mermaid
classDiagram

class GetPizzaBloc {
  +PizzaRepositoryBase pizzaRepository
  +add(GetPizzasRequested)
  +add(GetPizzasByCategoryRequested)
}

class GetPizzaState {
  +GetPizzaStatus status
  +List~PizzaEntity~ pizzas
  +List~CategoryEntity~ categories
  +String? selectedCategoryId
  +String? errorMessage
  +copyWith() GetPizzaState
}

class GetPizzaStatus {
  <<enumeration>>
  initial
  loading
  success
  failure
}

class GetPizzaEvent { <<abstract>> }
class GetPizzasRequested { }
class GetPizzasByCategoryRequested { +String categoryId }

GetPizzaBloc --> GetPizzaState
GetPizzaState --> GetPizzaStatus
GetPizzaEvent <|-- GetPizzasRequested
GetPizzaEvent <|-- GetPizzasByCategoryRequested
```

---

### CartBloc

```mermaid
classDiagram

class CartBloc {
  +CartRepositoryBase cartRepository
  -StreamSubscription _cartSubscription
}

class CartState {
  +CartStatus status
  +CartEntity cart
  +String? errorMessage
  +String? successMessage
  +int itemCount
  +bool hasItems
  +copyWith() CartState
}

class CartEvent { <<abstract>> }
class CartStarted { }
class CartItemAdded { +CartItemEntity item }
class CartItemRemoved { +String itemId }
class CartItemQuantityUpdated { +String itemId; +int quantity }
class CartCleared { }
class CartPromoApplied { +String code }
class _CartUpdated { +CartEntity cart }

CartBloc --> CartState
CartEvent <|-- CartStarted
CartEvent <|-- CartItemAdded
CartEvent <|-- CartItemRemoved
CartEvent <|-- CartItemQuantityUpdated
CartEvent <|-- CartCleared
CartEvent <|-- CartPromoApplied
CartEvent <|-- _CartUpdated
```

---

### PizzaCustomizationCubit

```mermaid
classDiagram

class PizzaCustomizationCubit {
  +initialize(pizza)
  +selectSize(size)
  +selectCrust(crust)
  +selectSauce(sauce)
  +toggleTopping(topping)
  +reset()
}

class PizzaCustomizationState {
  +PizzaEntity? pizza
  +double basePrice
  +PizzaSize size
  +CrustType crust
  +SauceType sauce
  +List~String~ extraToppings
  +double totalPrice
  +copyWith() PizzaCustomizationState
}

PizzaCustomizationCubit --> PizzaCustomizationState
```

---

### CheckoutBloc

```mermaid
classDiagram

class CheckoutBloc {
  +OrderRepositoryBase orderRepository
  +CartRepositoryBase cartRepository
}

class CheckoutState {
  +CheckoutStatus status
  +CartEntity cart
  +String deliveryAddress
  +String paymentMethod
  +OrderEntity? order
  +String? errorMessage
  +bool isValid
  +copyWith() CheckoutState
}

class CheckoutStatus {
  <<enumeration>>
  initial
  loading
  success
  failure
}

class CheckoutEvent { <<abstract>> }
class CheckoutStarted { }
class CheckoutAddressChanged { +String address }
class CheckoutPaymentChanged { +String paymentMethod }
class CheckoutSubmitted { +String userId }

CheckoutBloc --> CheckoutState
CheckoutState --> CheckoutStatus
CheckoutEvent <|-- CheckoutStarted
CheckoutEvent <|-- CheckoutAddressChanged
CheckoutEvent <|-- CheckoutPaymentChanged
CheckoutEvent <|-- CheckoutSubmitted
```

---

## 6. Widget Tree (Key Shared Widgets)

```mermaid
classDiagram

class MarioButton {
  +String label
  +VoidCallback? onPressed
  +bool isLoading
  +IconData? icon
  +Color backgroundColor
  +Color textColor
  +double height
  -AnimationController _controller
  -Animation~double~ _scaleAnimation
  +_onTapDown()
  +_onTapUp()
}

class PizzaIllustration {
  +double size
  +String crust
  +String sauce
  +List~String~ toppings
  +bool animateToppings
}
note for PizzaIllustration "Uses CustomPainter to render\npizza layers: shadow, crust,\nsauce, cheese, toppings"

class PizzaCard {
  +PizzaEntity pizza
  +VoidCallback onTap
  +VoidCallback onQuickAdd
  -AnimationController _addController
  +_handleAddTap()
}

class MarioBottomNav {
  +int currentIndex
  +ValueChanged~int~ onTap
}
note for MarioBottomNav "Reads CartBloc for cart badge count\nContext.select for performance"

class QuantityStepper {
  +int value
  +ValueChanged~int~ onChanged
  +int min
  +int max
}
note for QuantityStepper "Uses AnimatedSwitcher for\ncount change animation"

class OrderTimeline {
  +List~OrderTrackingStep~ steps
}

class MarioLoader {
  +double size
  +String label
}
note for MarioLoader "Rotating 🍕 emoji\nwith AnimationController"

MarioButton --> "AnimationController"
PizzaCard --> PizzaIllustration
PizzaCard --> "AnimationController"
MarioBottomNav --> "CartBloc (select)"
OrderTimeline --> "OrderTrackingStep"
```
