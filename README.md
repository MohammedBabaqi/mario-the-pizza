# 🍕 MARIO — Premium Italian Pizza Delivery App 🇮🇹

> A complete, production-ready artisanal pizza delivery mobile & web application built with **Flutter (MVVM Architecture)**, a high-performance **Go REST API backend**, **SQLite offline storage**, and an interactive **OpenStreetMap GPS delivery picker**.

---

## 🌟 Overview

**MARIO** is an authentic Italian pizzeria experience crafted with attention to visual design, smooth animations, and solid architectural foundations. It features the official **Il Tricolore** color palette (*Verde Italiano*, *Rosso Pomodoro*, and *Parmigiano Gold*), offline persistence, real-time pizza customization, and full backend synchronization.

---

## 📑 Project Requirements Compliance (متطلبات المشروع)

This project strictly adheres to and fully implements all academic and technical project specifications:

### 🎨 FrontEnd Requirements (10 / 10)

| # | Requirement | Implementation in Code | Description |
|---|---|---|---|
| 1 | **AppBar** | `lib/views/home_screen.dart`<br>`lib/views/cart_screen.dart` | Custom responsive AppBars with dynamic delivery address selector, clear actions, and cart badge counters. |
| 2 | **Drawer** | `lib/views/app_drawer.dart` | Full Italian-themed navigation drawer featuring Tricolore accents, user account card, categorized sections (Menu, Activity, Settings), and Dark Mode switch. |
| 3 | **NavigationBar** | `lib/widgets/bottom_nav.dart` | Custom `MarioBottomNav` with active pill indicators, animated icons, and real-time cart badge counter. |
| 4 | **Login & SignUp** | `lib/views/sign_in_screen.dart`<br>`lib/views/sign_up_screen.dart` | Complete authentication flow with input validation, "Remember Me" credentials, demo login buttons, and SQLite user persistence. |
| 5 | **ListView** | `lib/views/home_screen.dart`<br>`lib/views/cart_screen.dart` | Horizontal category list, pizza recommendations, and vertical `ListView.separated` for cart items and order histories. |
| 6 | **GridView** | `lib/views/search_screen.dart`<br>`lib/views/favorites_screen.dart` | 2-column responsive `GridView.builder` (`childAspectRatio: 0.72`) rendering pizza cards with quick-add actions. |
| 7 | **Card** | `lib/widgets/pizza_card.dart`<br>`lib/views/checkout_screen.dart` | Reusable `PizzaCard` with elevation and corner radii, plus cards for Delivery Address, Payment Methods, and Order Summary. |
| 8 | **Passing Parameters** | `lib/views/pizza_details_screen.dart`<br>`lib/views/customization_screen.dart` | Passes `pizzaId` through route navigations and widget constructors to dynamically load and display pizza models. |
| 9 | **Navigation Class Methods** | `lib/utils/navigation.dart` | Static helper class encapsulating all route transitions (`Navigation.goToHome`, `goToPizzaDetails`, `goToCart`, `goToOrders`, etc.). |
| 10 | **Clipper** | `lib/widgets/pizza_clipper.dart` | Custom `PizzaWaveClipper` and `ClippedHeader` using `CustomClipper<Path>` for organic wave curves on authentication and welcome screens. |

### ⚙️ BackEnd Requirements (3 / 3)

| # | Requirement | Implementation in Code | Description |
|---|---|---|---|
| 1 | **Go REST API** | `backend/main.go` | Lightweight pure Go server on `:8080` handling `/api/pizzas`, `/api/orders`, `/api/auth`, with CORS, JSON serialization, and structured request logging. |
| 2 | **MVVM Architecture** | `lib/models/`<br>`lib/viewmodels/`<br>`lib/views/`<br>`lib/services/` | Strict separation of concerns: Models represent business data, ViewModels manage reactive state via `ChangeNotifier`, Views handle UI, and Services abstract network & storage. |
| 3 | **LocalStorage** | `lib/services/local_db_service.dart`<br>`lib/services/prefs_service.dart` | **SQLite** (`sqflite`): Full offline CRUD database for pizzas, users, and orders with live management in `DatabaseScreen`.<br>**SharedPreferences**: Persists theme mode, auth tokens, search queries, and remembered login email. |

---

## 🚀 Key Features

* 📍 **Free OpenStreetMap & GPS Delivery Picker**: Interactive map using `flutter_map` and device GPS (`geolocator`) with live Nominatim reverse geocoding to resolve street names without paid Google Maps APIs.
* 🍕 **Real-time Pizza Customizer**: Interactive size selection (Small, Medium, Large), crust choices (Classic, Thin, Cheese Stuffed, Gluten-Free), and live ingredient pricing calculation.
* 🛒 **Smart Cart & Orders**: Merges duplicate pizza configurations, tracks item counts, supports promotional coupons (`MARIO20`), and persists orders locally and to the Go backend.
* 🌓 **Adaptive Theme System**: Supports Light Mode, Dark Mode, and Italian Tricolore Theme with persistent preferences.
* 🛡️ **Production-Ready Permissions**:
  * Android: `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`.
  * iOS: `NSLocationWhenInUseUsageDescription`.
* 📱 **Custom Flat App Icon**: Artisanal flat-design pizza icon with a 45° long shadow rendered across all Android mipmaps, iOS AppIconset, and Web icons.

---

## 📂 Project Structure

```
pizza/
├── android/                    # Android native project & manifest permissions
├── assets/
│   └── icons/                  # App icons (mario_minimal.svg, app_icon.png)
├── backend/                    # Go REST API Server
│   ├── data/                   # Pizza & ingredient mock database
│   ├── handlers/               # Auth, Pizza, and Order HTTP handlers
│   ├── middleware/             # CORS, logging, and JWT auth middleware
│   ├── models/                 # Go data models (Pizza, Order, User)
│   ├── go.mod
│   └── main.go                 # Go API entrypoint (:8080)
├── ios/                        # iOS native project & Info.plist permissions
├── lib/                        # Flutter Application Source
│   ├── models/                 # Pizza, CartItem, Order, User, Ingredient models
│   ├── services/               # ApiService, LocalDbService (SQLite), PrefsService, AuthService
│   ├── utils/                  # AppColors, AppTheme, AppTypography, Navigation, Constants
│   ├── viewmodels/             # AuthVM, CartVM, PizzaVM, OrderVM, ThemeVM, CustomizationVM
│   ├── views/                  # UI screens (Home, Details, Cart, Checkout, Auth, Map, etc.)
│   ├── widgets/                # Reusable UI components (PizzaCard, BottomNav, Clippers, Buttons)
│   └── app.dart                # MaterialApp setup with Provider providers & routes
├── test/                       # Unit & Widget automated tests
├── web/                        # Flutter Web manifests & icons
├── pubspec.yaml                # Flutter dependencies & assets
└── README.md                   # Project documentation
```

---

## 🛠️ Setup & Running Instructions

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.29+ / Dart 3.12+)
* [Go](https://go.dev/dl/) (v1.20+)

### 1. Run the Go Backend API
Open a terminal and start the Go server:
```bash
cd backend
go run main.go
```
The server will start on `http://localhost:8080` with endpoints:
* `GET /api/pizzas` — List all pizzas
* `GET /api/pizzas/categories` — List pizza categories
* `GET /api/pizzas/ingredients` — List toppings and crusts
* `POST /api/orders` — Place a new order
* `POST /api/auth/signin` — Authenticate user
* `POST /api/auth/signup` — Register new user
* `GET /api/health` — Health check

### 2. Run the Flutter App
In a new terminal at the project root:
```bash
# Get dependencies
flutter pub get

# Run on Chrome (Web)
flutter run -d chrome

# Run on connected Android / iOS device
flutter run
```

### 3. One-Click Launcher (Windows)
You can also double-click [start.bat](file:///c:/Users/Mohammed%20Babaqi/Desktop/flutter%20projects/pizza/start.bat) to launch both the Go backend and Flutter app simultaneously.

---

## 🧪 Testing & Code Quality

Run the automated test suite:
```bash
flutter test
```
* **Status**: `All 7 tests passed!` (Coverage includes CartViewModel logic, CustomizationViewModel pricing, LocalDbService CRUD, LocationPickerScreen rendering, and Auth flows).

Run static analysis:
```bash
flutter analyze
```
* **Status**: `No issues found! (0 Warnings / 0 Errors)`.

---

## 🔑 Demo Credentials

To quickly test the application, you can use either the demo buttons on the Sign In screen or enter:
* **Email**: `m@gmail.com`
* **Password**: `123456`

*(Or register any new account; it will automatically save to the offline SQLite database and synchronize with the Go backend).*

---

## 👨‍💻 Author
* **Developer**: Mohammed Babaqi
* **Email**: mbabaqi2020@gmail.com
* **Project**: Mario Pizza Delivery App
