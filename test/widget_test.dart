import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mario/app.dart';
import 'package:mario/services/api_service.dart';
import 'package:mario/services/auth_service.dart';
import 'package:mario/services/local_db_service.dart';
import 'package:mario/services/prefs_service.dart';
import 'package:mario/models/pizza_model.dart';
import 'package:mario/models/cart_item_model.dart';
import 'package:mario/viewmodels/cart_viewmodel.dart';
import 'package:mario/viewmodels/customization_viewmodel.dart';
import 'package:mario/views/location_picker_screen.dart';
import 'package:mario/widgets/bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MarioApp builds and renders successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final prefsService = PrefsService(prefs);
    final apiService = ApiService();
    final localDbService = LocalDbService();

    await tester.pumpWidget(
      MarioApp(
        prefsService: prefsService,
        apiService: apiService,
        localDbService: localDbService,
      ),
    );

    expect(find.byType(MarioApp), findsOneWidget);
  });

  test('CartViewModel merges identical pizza configurations and increments quantity', () {
    final cart = CartViewModel();
    const pizza = PizzaModel.craftYourOwn;

    final item1 = CartItemModel(
      id: 'item_1',
      pizza: pizza,
      size: PizzaSize.large,
      crust: CrustType.cheesy,
      sauce: SauceType.spicy,
      extraToppings: const ['Pepperoni', 'Extra Cheese'],
      quantity: 1,
    );

    final item2 = CartItemModel(
      id: 'item_2',
      pizza: pizza,
      size: PizzaSize.large,
      crust: CrustType.cheesy,
      sauce: SauceType.spicy,
      extraToppings: const ['Extra Cheese', 'Pepperoni'], // Same toppings in different order
      quantity: 2,
    );

    cart.addItem(item1);
    expect(cart.items.length, 1);
    expect(cart.items.first.quantity, 1);

    cart.addItem(item2);
    // Should NOT create duplicate row; should merge into 1 item with quantity 3
    expect(cart.items.length, 1);
    expect(cart.items.first.quantity, 3);
  });

  test('CustomizationViewModel calculates dynamic ingredient prices and calories', () {
    final vm = CustomizationViewModel();
    vm.initialize(PizzaModel.craftYourOwn);

    // Base price is 7.99 for craftYourOwn
    expect(vm.basePrice, 7.99);

    // Medium size (+2.00), Classic crust (+0.00), Tomato sauce (+0.00)
    expect(vm.totalPrice, 9.99);

    // Add Extra Cheese (+1.50) and Basil (+0.50)
    vm.toggleTopping('Extra Cheese');
    vm.toggleTopping('Basil');

    expect(vm.toppingsPrice, 2.00);
    expect(vm.totalPrice, 11.99);

    // Check calories: base 550 + 110 (cheese) + 5 (basil) = 665
    expect(vm.extraCalories, 115);
    expect(vm.totalCalories, 665);
  });

  testWidgets('LocationPickerScreen builds and renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const LocationPickerScreen(
          initialAddress: '123 Main St',
          initialLat: 15.3694,
          initialLng: 44.1910,
        ),
      ),
    );

    expect(find.text('Select Delivery Location 📍'), findsOneWidget);
    expect(find.text('Add Details 📝'), findsOneWidget);
    expect(find.text('Quick Pin 📍'), findsOneWidget);
  });

  test('LocalDbService and AuthService authenticate m@gmail.com and remember email', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final prefsService = PrefsService(prefs);
    final localDb = LocalDbService(prefsService);
    final apiService = ApiService();
    final authService = AuthService(apiService, prefsService, localDb);

    // 1. Verify m@gmail.com is seeded in local database
    final seededUser = await localDb.getUserByEmail('m@gmail.com');
    expect(seededUser, isNotNull);
    expect(seededUser!.email, 'm@gmail.com');

    // 2. Sign in with m@gmail.com and 123456
    final signedIn = await authService.signIn(email: 'm@gmail.com', password: '123456');
    expect(signedIn.email, 'm@gmail.com');

    // 3. Verify email is remembered for next login
    expect(prefsService.getRememberedEmail(), 'm@gmail.com');
  });

  testWidgets('MarioBottomNav renders Cart tab with badge and no Profile tab', (WidgetTester tester) async {
    final cartVM = CartViewModel();
    cartVM.addItem(CartItemModel(
      id: 'test_item',
      pizza: PizzaModel.craftYourOwn,
      size: PizzaSize.medium,
      crust: CrustType.classic,
      sauce: SauceType.tomato,
      extraToppings: const [],
      quantity: 3,
    ));

    await tester.pumpWidget(
      ChangeNotifierProvider<CartViewModel>.value(
        value: cartVM,
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MarioBottomNav(
              currentIndex: 4,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // Badge counter
    expect(find.text('Profile'), findsNothing); // Profile moved to AppDrawer & AppBar
  });

  test('LocalDbService performs real food CRUD operations and persists users', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final prefsService = PrefsService(prefs);
    final localDb = LocalDbService(prefsService);

    // 1. Insert a real food item
    const newFood = PizzaModel(
      id: 'custom_truffle_special',
      name: 'Custom Truffle Special',
      description: 'Real custom pizza in SQLite',
      price: 15.99,
      rating: 5.0,
      calories: 820,
      protein: 30,
      fat: 25,
      carbs: 70,
      ingredients: ['Truffle', 'Mozzarella', 'Mushrooms'],
      category: 'special',
      imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591',
      isPopular: true,
      isRecommended: true,
    );

    await localDb.insertPizza(newFood);
    final allPizzas = await localDb.getCachedPizzas();
    expect(allPizzas.any((p) => p.id == 'custom_truffle_special'), isTrue);

    // 2. Update the food item price
    final updatedFood = newFood.copyWith(price: 17.99);
    await localDb.updatePizza(updatedFood);
    final fetched = await localDb.getPizzaById('custom_truffle_special');
    expect(fetched?.price, 17.99);

    // 3. Delete the food item
    await localDb.deletePizza('custom_truffle_special');
    final afterDelete = await localDb.getPizzaById('custom_truffle_special');
    expect(afterDelete, isNull);

    // 4. Test user CRUD in database
    final allUsers = await localDb.getAllUsers();
    expect(allUsers.any((u) => u.email == 'm@gmail.com'), isTrue);
  });
}
