# 🍕 MARIO — Premium Italian Pizza Delivery App 🇮🇹

> A university demonstration project for an artisanal pizza delivery experience, built with **Flutter (MVVM Architecture)**, a **Go REST API backend**, local storage, and an interactive **OpenStreetMap GPS delivery picker**.

---

## 🌟 Overview

**MARIO** is an academic Flutter application that demonstrates common mobile UI components, MVVM-style separation, API communication, local persistence, authentication, pizza customization, cart checkout, and order tracking. The project is designed for classroom demonstration rather than production deployment.

---

## 📑 Project Requirements Compliance (متطلبات المشروع)

The current application demonstrates the following academic requirements:

### 🎨 FrontEnd Requirements (10 / 10)

| # | Requirement | Implementation in Code | Description |
|---|---|---|---|
| 1 | **AppBar** | `lib/views/home_screen.dart`<br>`lib/views/cart_screen.dart` | Custom responsive AppBars with dynamic delivery address selector, clear actions, and cart badge counters. |
| 2 | **Drawer** | `lib/views/app_drawer.dart` | Full Italian-themed navigation drawer featuring Tricolore accents, user account card, categorized sections (Menu, Activity, Settings), and Dark Mode switch. |
| 3 | **NavigationBar** | `lib/widgets/bottom_nav.dart` | Custom `MarioBottomNav` with active pill indicators, animated icons, and real-time cart badge counter. |
| 4 | **Login & SignUp** | `lib/views/sign_in_screen.dart`<br>`lib/views/sign_up_screen.dart` | Authentication through the Go API, remembered email/session data, built-in offline demo accounts, and locally cached user profiles. |
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
| 3 | **LocalStorage** | `lib/services/local_db_service.dart`<br>`lib/services/prefs_service.dart` | **SQLite** (`sqflite`) stores pizzas and users on supported native platforms. **SharedPreferences** stores theme, session data, favorites, search history, remembered email, and browser fallback data. Orders are held by the running Go server and are not written to SQLite. |

---

## 🚀 Key Features

* 📍 **Free OpenStreetMap & GPS Delivery Picker**: Interactive map using `flutter_map` and device GPS (`geolocator`) with live Nominatim reverse geocoding to resolve street names without paid Google Maps APIs.
* 🍕 **Real-time Pizza Customizer**: Interactive size selection (Small, Medium, Large), crust choices (Classic, Thin, Cheese Stuffed, Gluten-Free), and live ingredient pricing calculation.
* 🛒 **Cart & Orders**: Merges identical pizza configurations, tracks quantities, validates checkout details, sends orders to the Go API, and displays order history and tracking screens. Server order data resets when the Go server restarts.
* 🌓 **Adaptive Theme System**: Supports Light Mode, Dark Mode, and Italian Tricolore Theme with persistent preferences.
* 🛡️ **Platform Permissions**:
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
│   ├── services/               # API, authentication, SQLite/native, and preferences/browser storage
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
* A Flutter release that includes Dart 3.12.2 or newer (verified locally with Flutter 3.44.4)
* [Go](https://go.dev/dl/) 1.21 or newer

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

The default backend addresses are:

* Web, Windows, and iOS simulator: `http://localhost:8080/api`
* Android Emulator: `http://10.0.2.2:8080/api`

For a physical phone, replace the API host in `lib/services/api_service.dart` with the computer's local-network IP address and keep both devices on the same network.

### 3. One-Click Launcher (Windows)
Double-click `start.bat` to start the Go backend and launch the Flutter web app in Chrome.

### 4. What works without internet?

* The application tries the Go API first.
* If pizza requests fail, it loads the cached/default pizza list from SQLite on native platforms or SharedPreferences/browser storage on Web.
* The remembered email, cached user profile, authentication token, theme, favorites, and search history are stored locally.
* If a remembered session exists, the application can restore the cached user when the backend is unavailable.
* After signing out, offline sign-in is limited to the built-in demo accounts; incorrect passwords are rejected.
* Cart contents are kept in application memory and disappear when the app process is closed.
* Creating or loading server orders needs the Go backend. Orders stored by the server disappear when the server restarts.
* Remote pizza images, OpenStreetMap tiles, and Nominatim address lookup need internet. The UI shows a pizza placeholder when a remote image is unavailable.

### 5. View the local database/storage

Inside the app:

1. Sign in or continue as guest.
2. Open the menu icon in the top-left corner.
3. Select **SQLite Database & Data**.
4. Use the **Pizzas**, **Users**, and storage-information tabs to inspect the current records.

On Android and other supported native platforms, this screen reads the real `mario_pizza.db` SQLite database. On Web, it displays the equivalent browser-persisted data from SharedPreferences; Web does not create a SQLite database file.

---

## 🧪 Testing & Code Quality

Run the automated test suite:
```bash
flutter test
```
* **Coverage**: Cart behavior and pricing, customization calculations, offline authentication rules, local data CRUD, location-screen rendering, and bottom navigation.

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

When the backend is running, newly registered users are created in the Go server's in-memory user store and cached locally. If the backend is offline, sign-up creates a local profile and keeps the new session on that device, but a signed-out offline user cannot authenticate again unless it is one of the built-in demo accounts.

---

## 👨‍💻 Author
* **Developer**: Mohammed Babaqi
* **Email**: mbabaqi2020@gmail.com
* **Project**: Mario Pizza Delivery App
