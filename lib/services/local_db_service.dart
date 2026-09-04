import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pizza_model.dart';
import '../models/user_model.dart';

import 'prefs_service.dart';

/// SQLite local database service (Requirement: LocalStorage sqlite).
/// Provides structured tables for Pizzas AND Users, initial seed data on creation,
/// and full CRUD operations for both.
class LocalDbService {
  final PrefsService? _prefs;
  static Database? _database;
  static const String tablePizzas = 'pizzas';
  static const String tableUsers = 'users';

  LocalDbService([this._prefs]);

  /// Initial pre-seeded users in SQLite.
  static final List<UserModel> initialSeedUsers = [
    UserModel(
      uid: 'user_1',
      email: 'demo@mario.com',
      displayName: 'Mario Chef',
      photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&q=80',
      phoneNumber: '+1 555-0199',
      defaultAddress: '123 Mario Plaza, Apt 4B',
      createdAt: DateTime.now(),
    ),
    UserModel(
      uid: 'user_2',
      email: 'user@example.com',
      displayName: 'Mohammed Babaqi',
      photoUrl: null,
      phoneNumber: '+966 50 123 4567',
      defaultAddress: '456 King Fahd Road',
      createdAt: DateTime.now(),
    ),
    UserModel(
      uid: 'user_m',
      email: 'm@gmail.com',
      displayName: 'Mohammed Babaqi',
      photoUrl: null,
      phoneNumber: '+966 50 123 4567',
      defaultAddress: 'King Fahd Road, Apt 4B',
      createdAt: DateTime.now(),
    ),
  ];

  /// Initial pre-seeded pizzas stored in SQLite (matches Go backend seed.go 1:1).
  static const List<PizzaModel> initialSeedPizzas = [
    PizzaModel(
      id: 'margherita',
      name: 'Margherita',
      description: 'Classic tomato, fresh mozzarella and aromatic basil on a perfectly baked crust',
      price: 8.99,
      rating: 4.8,
      calories: 720,
      protein: 28,
      fat: 24,
      carbs: 82,
      ingredients: ['Tomato', 'Mozzarella', 'Basil', 'Olive Oil'],
      category: 'classic',
      imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&h=600&fit=crop',
      isPopular: true,
      isRecommended: true,
    ),
    PizzaModel(
      id: 'pepperoni',
      name: 'Pepperoni',
      description: 'Generous layers of spicy pepperoni over melted mozzarella and rich tomato sauce',
      price: 10.99,
      rating: 4.9,
      calories: 850,
      protein: 34,
      fat: 32,
      carbs: 78,
      ingredients: ['Pepperoni', 'Mozzarella', 'Tomato Sauce'],
      category: 'classic',
      imageUrl: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600&h=600&fit=crop',
      isPopular: true,
      isRecommended: true,
    ),
    PizzaModel(
      id: 'four_cheese',
      name: 'Four Cheese',
      description: 'A luxurious blend of mozzarella, gorgonzola, parmesan and fontina',
      price: 12.99,
      rating: 4.7,
      calories: 920,
      protein: 38,
      fat: 42,
      carbs: 68,
      ingredients: ['Mozzarella', 'Gorgonzola', 'Parmesan', 'Fontina'],
      category: 'special',
      imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&h=600&fit=crop',
      isPopular: true,
      isRecommended: false,
    ),
    PizzaModel(
      id: 'spicy_diavola',
      name: 'Spicy Diavola',
      description: 'Fiery salami, fresh chili, and red pepper flakes for the brave hearted',
      price: 11.99,
      rating: 4.6,
      calories: 810,
      protein: 30,
      fat: 28,
      carbs: 80,
      ingredients: ['Spicy Salami', 'Chili', 'Red Pepper', 'Mozzarella', 'Tomato Sauce'],
      category: 'spicy',
      imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&h=600&fit=crop',
      isPopular: false,
      isRecommended: true,
    ),
    PizzaModel(
      id: 'veggie_garden',
      name: 'Veggie Garden',
      description: 'A colorful medley of grilled vegetables, olives, and fresh herbs',
      price: 9.99,
      rating: 4.5,
      calories: 620,
      protein: 18,
      fat: 16,
      carbs: 88,
      ingredients: ['Bell Pepper', 'Mushrooms', 'Olives', 'Onions', 'Tomato', 'Mozzarella'],
      category: 'veggie',
      imageUrl: 'https://images.unsplash.com/photo-1571407970349-bc81e7e96d47?w=600&h=600&fit=crop',
      isPopular: false,
      isRecommended: false,
    ),
    PizzaModel(
      id: 'bbq_chicken',
      name: 'BBQ Chicken',
      description: 'Smoky BBQ sauce, tender chicken, red onions and a blend of cheeses',
      price: 13.99,
      rating: 4.8,
      calories: 880,
      protein: 42,
      fat: 30,
      carbs: 76,
      ingredients: ['Chicken', 'BBQ Sauce', 'Red Onion', 'Mozzarella', 'Cheddar'],
      category: 'special',
      imageUrl: 'https://images.unsplash.com/photo-1594007654729-407eedc4be65?w=600&h=600&fit=crop',
      isPopular: true,
      isRecommended: true,
    ),
    PizzaModel(
      id: 'mushroom_truffle',
      name: 'Mushroom Truffle',
      description: 'Wild mushroom mix with truffle oil, garlic cream, and aged parmesan',
      price: 14.99,
      rating: 4.9,
      calories: 780,
      protein: 26,
      fat: 34,
      carbs: 72,
      ingredients: ['Wild Mushrooms', 'Truffle Oil', 'Garlic Cream', 'Parmesan'],
      category: 'special',
      imageUrl: 'https://images.unsplash.com/photo-1590947132387-155cc02f3212?w=600&h=600&fit=crop',
      isPopular: false,
      isRecommended: true,
    ),
    PizzaModel(
      id: 'basil_special',
      name: 'Basil Special',
      description: 'Fresh buffalo mozzarella, cherry tomatoes, pesto, and abundant fresh basil',
      price: 11.49,
      rating: 4.7,
      calories: 690,
      protein: 24,
      fat: 22,
      carbs: 78,
      ingredients: ['Buffalo Mozzarella', 'Cherry Tomatoes', 'Pesto', 'Basil'],
      category: 'classic',
      imageUrl: 'https://images.unsplash.com/photo-1604382355076-af4b0eb60143?w=600&h=600&fit=crop',
      isPopular: true,
      isRecommended: false,
    ),
  ];

  static final List<PizzaModel> _inMemoryPizzas = List.from(initialSeedPizzas);
  static final List<UserModel> _inMemoryUsers = List.from(initialSeedUsers);

  /// Get or initialize the database.
  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (_) {
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'mario_pizza.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // Table 1: Pizzas
        await db.execute('''
          CREATE TABLE $tablePizzas (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            price REAL NOT NULL,
            rating REAL NOT NULL,
            calories INTEGER NOT NULL,
            protein INTEGER NOT NULL,
            fat INTEGER NOT NULL,
            carbs INTEGER NOT NULL,
            ingredients TEXT NOT NULL,
            category TEXT NOT NULL,
            imageUrl TEXT NOT NULL,
            isPopular INTEGER NOT NULL,
            isRecommended INTEGER NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');

        // Table 2: Users (Requirement: SQLite for users)
        await db.execute('''
          CREATE TABLE $tableUsers (
            uid TEXT PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            displayName TEXT NOT NULL,
            photoUrl TEXT,
            phoneNumber TEXT,
            defaultAddress TEXT,
            createdAt TEXT NOT NULL
          )
        ''');

        // PRE-SEED SQLITE: Insert initial seed pizzas and users
        final batch = db.batch();
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final pizza in initialSeedPizzas) {
          batch.insert(tablePizzas, _pizzaToRow(pizza, now));
        }
        for (final user in initialSeedUsers) {
          batch.insert(tableUsers, _userToRow(user));
        }
        await batch.commit(noResult: true);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableUsers (
              uid TEXT PRIMARY KEY,
              email TEXT UNIQUE NOT NULL,
              displayName TEXT NOT NULL,
              photoUrl TEXT,
              phoneNumber TEXT,
              defaultAddress TEXT,
              createdAt TEXT NOT NULL
            )
          ''');
          final batch = db.batch();
          for (final user in initialSeedUsers) {
            batch.insert(tableUsers, _userToRow(user), conflictAlgorithm: ConflictAlgorithm.replace);
          }
          await batch.commit(noResult: true);
        }
      },
    );
  }

  // ── Helper Row Converters: Pizzas ─────────────────────────────────

  static Map<String, dynamic> _pizzaToRow(PizzaModel pizza, [int? timestamp]) {
    return {
      'id': pizza.id,
      'name': pizza.name,
      'description': pizza.description,
      'price': pizza.price,
      'rating': pizza.rating,
      'calories': pizza.calories,
      'protein': pizza.protein,
      'fat': pizza.fat,
      'carbs': pizza.carbs,
      'ingredients': jsonEncode(pizza.ingredients),
      'category': pizza.category,
      'imageUrl': pizza.imageUrl,
      'isPopular': pizza.isPopular ? 1 : 0,
      'isRecommended': pizza.isRecommended ? 1 : 0,
      'cached_at': timestamp ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  static PizzaModel _rowToPizza(Map<String, dynamic> row) {
    List<String> ingredients = [];
    try {
      ingredients = List<String>.from(jsonDecode(row['ingredients'] as String));
    } catch (_) {
      ingredients = [];
    }

    return PizzaModel(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String,
      price: (row['price'] as num).toDouble(),
      rating: (row['rating'] as num).toDouble(),
      calories: row['calories'] as int,
      protein: row['protein'] as int,
      fat: row['fat'] as int,
      carbs: row['carbs'] as int,
      ingredients: ingredients,
      category: row['category'] as String,
      imageUrl: row['imageUrl'] as String,
      isPopular: (row['isPopular'] as int) == 1,
      isRecommended: (row['isRecommended'] as int) == 1,
    );
  }

  // ── Helper Row Converters: Users ──────────────────────────────────

  static Map<String, dynamic> _userToRow(UserModel user) {
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'phoneNumber': user.phoneNumber,
      'defaultAddress': user.defaultAddress,
      'createdAt': user.createdAt.toIso8601String(),
    };
  }

  static UserModel _rowToUser(Map<String, dynamic> row) {
    return UserModel(
      uid: row['uid'] as String,
      email: row['email'] as String,
      displayName: row['displayName'] as String? ?? '',
      photoUrl: row['photoUrl'] as String?,
      phoneNumber: row['phoneNumber'] as String?,
      defaultAddress: row['defaultAddress'] as String?,
      createdAt: row['createdAt'] != null
          ? DateTime.tryParse(row['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // ── USER CRUD Operations (Requirement: SQLite for Users) ──────────

  /// [CREATE / INSERT USER] Insert or replace a user in SQLite.
  Future<void> insertUser(UserModel user) async {
    if (kIsWeb) {
      _inMemoryUsers.removeWhere((u) => u.uid == user.uid || u.email.toLowerCase() == user.email.toLowerCase());
      _inMemoryUsers.add(user);
      if (_prefs != null) {
        await _prefs.saveUserInDb(user.toJson());
      }
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert(
      tableUsers,
      _userToRow(user),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// [READ USER BY EMAIL] Find a user by email from SQLite.
  Future<UserModel?> getUserByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (kIsWeb) {
      try {
        return _inMemoryUsers.firstWhere((u) => u.email.trim().toLowerCase() == normalized);
      } catch (_) {
        if (_prefs != null) {
          final savedList = _prefs.getSavedUsersDb();
          for (final raw in savedList) {
            final user = UserModel.fromJson(raw);
            if (user.email.trim().toLowerCase() == normalized) {
              _inMemoryUsers.add(user);
              return user;
            }
          }
        }
        return null;
      }
    }
    try {
      final db = await database;
      if (db == null) return _findInSeedOrMemory(normalized);
      final rows = await db.query(
        tableUsers,
        where: 'LOWER(email) = ?',
        whereArgs: [normalized],
        limit: 1,
      );
      if (rows.isEmpty) return _findInSeedOrMemory(normalized);
      return _rowToUser(rows.first);
    } catch (_) {
      return _findInSeedOrMemory(normalized);
    }
  }

  UserModel? _findInSeedOrMemory(String normalized) {
    try {
      return _inMemoryUsers.firstWhere((u) => u.email.trim().toLowerCase() == normalized);
    } catch (_) {
      try {
        return initialSeedUsers.firstWhere((u) => u.email.trim().toLowerCase() == normalized);
      } catch (_) {
        return null;
      }
    }
  }

  /// [READ USER BY ID] Find a user by uid from SQLite.
  Future<UserModel?> getUserById(String uid) async {
    if (kIsWeb) {
      try {
        return _inMemoryUsers.firstWhere((u) => u.uid == uid);
      } catch (_) {
        return null;
      }
    }
    try {
      final db = await database;
      if (db == null) return _findInSeedOrMemoryById(uid);
      final rows = await db.query(
        tableUsers,
        where: 'uid = ?',
        whereArgs: [uid],
        limit: 1,
      );
      if (rows.isEmpty) return _findInSeedOrMemoryById(uid);
      return _rowToUser(rows.first);
    } catch (_) {
      return _findInSeedOrMemoryById(uid);
    }
  }

  UserModel? _findInSeedOrMemoryById(String uid) {
    try {
      return _inMemoryUsers.firstWhere((u) => u.uid == uid);
    } catch (_) {
      try {
        return initialSeedUsers.firstWhere((u) => u.uid == uid);
      } catch (_) {
        return null;
      }
    }
  }

  /// [READ ALL USERS] Get all registered users from SQLite.
  Future<List<UserModel>> getAllUsers() async {
    if (kIsWeb) {
      if (_prefs != null) {
        final savedRaw = _prefs.getSavedUsersDb();
        for (final m in savedRaw) {
          final u = UserModel.fromJson(m);
          if (!_inMemoryUsers.any((existing) => existing.uid == u.uid || existing.email.toLowerCase() == u.email.toLowerCase())) {
            _inMemoryUsers.add(u);
          }
        }
      }
      return List.unmodifiable(_inMemoryUsers);
    }
    try {
      final db = await database;
      if (db == null) return initialSeedUsers;
      final rows = await db.query(tableUsers, orderBy: 'createdAt DESC');
      if (rows.isEmpty) return initialSeedUsers;
      return rows.map(_rowToUser).toList();
    } catch (_) {
      return initialSeedUsers;
    }
  }

  /// [UPDATE USER] Update existing user in SQLite.
  Future<void> updateUser(UserModel user) async {
    if (kIsWeb) {
      final idx = _inMemoryUsers.indexWhere((u) => u.uid == user.uid);
      if (idx != -1) {
        _inMemoryUsers[idx] = user;
      } else {
        _inMemoryUsers.add(user);
      }
      if (_prefs != null) {
        await _prefs.saveUserInDb(user.toJson());
      }
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.update(
      tableUsers,
      _userToRow(user),
      where: 'uid = ?',
      whereArgs: [user.uid],
    );
  }

  /// [DELETE USER] Delete user from SQLite.
  Future<void> deleteUser(String uid) async {
    _inMemoryUsers.removeWhere((u) => u.uid == uid);
    if (_prefs != null) {
      await _prefs.deleteUserInDb(uid);
    }
    if (kIsWeb) return;
    try {
      final db = await database;
      if (db == null) return;
      await db.delete(tableUsers, where: 'uid = ?', whereArgs: [uid]);
    } catch (_) {}
  }

  // ── PIZZA CRUD Operations ─────────────────────────────────────────

  /// [CREATE / INSERT PIZZA] Insert a single pizza into SQLite.
  Future<void> insertPizza(PizzaModel pizza) async {
    _inMemoryPizzas.removeWhere((p) => p.id == pizza.id);
    _inMemoryPizzas.add(pizza);
    if (_prefs != null) {
      await _prefs.savePizzaInDb(pizza.toJson());
    }
    if (kIsWeb) return;
    try {
      final db = await database;
      if (db == null) return;
      await db.insert(
        tablePizzas,
        _pizzaToRow(pizza),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// [READ / SELECT ALL PIZZAS] Get all cached pizzas from SQLite.
  Future<List<PizzaModel>> getCachedPizzas() async {
    if (kIsWeb) {
      if (_prefs != null) {
        final savedRaw = _prefs.getSavedPizzasDb();
        if (savedRaw.isNotEmpty) {
          final loaded = savedRaw.map((m) => PizzaModel.fromJson(m)).toList();
          _inMemoryPizzas.clear();
          _inMemoryPizzas.addAll(loaded);
          return List.unmodifiable(_inMemoryPizzas);
        } else {
          // Initialize persistent store with default pizzas
          await _prefs.saveAllPizzasInDb(initialSeedPizzas.map((p) => p.toJson()).toList());
        }
      }
      return List.unmodifiable(_inMemoryPizzas);
    }
    try {
      final db = await database;
      if (db == null) return List.unmodifiable(_inMemoryPizzas);
      final rows = await db.query(tablePizzas, orderBy: 'rating DESC');
      if (rows.isEmpty) return List.unmodifiable(_inMemoryPizzas);
      return rows.map(_rowToPizza).toList();
    } catch (_) {
      return List.unmodifiable(_inMemoryPizzas);
    }
  }

  /// [READ / SELECT PIZZA BY ID] Get a single pizza by ID from SQLite.
  Future<PizzaModel?> getPizzaById(String id) async {
    if (!kIsWeb) {
      try {
        final db = await database;
        if (db != null) {
          final rows = await db.query(tablePizzas, where: 'id = ?', whereArgs: [id], limit: 1);
          if (rows.isNotEmpty) return _rowToPizza(rows.first);
        }
      } catch (_) {}
    }
    try {
      return _inMemoryPizzas.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// [UPDATE PIZZA] Update an existing pizza in SQLite.
  Future<void> updatePizza(PizzaModel pizza) async {
    final index = _inMemoryPizzas.indexWhere((p) => p.id == pizza.id);
    if (index != -1) {
      _inMemoryPizzas[index] = pizza;
    } else {
      _inMemoryPizzas.add(pizza);
    }
    if (_prefs != null) {
      await _prefs.savePizzaInDb(pizza.toJson());
    }
    if (kIsWeb) return;
    try {
      final db = await database;
      if (db == null) return;
      await db.update(
        tablePizzas,
        _pizzaToRow(pizza),
        where: 'id = ?',
        whereArgs: [pizza.id],
      );
    } catch (_) {}
  }

  /// [DELETE PIZZA] Delete a pizza by ID from SQLite.
  Future<void> deletePizza(String id) async {
    _inMemoryPizzas.removeWhere((p) => p.id == id);
    if (_prefs != null) {
      await _prefs.deletePizzaInDb(id);
    }
    if (kIsWeb) return;
    try {
      final db = await database;
      if (db == null) return;
      await db.delete(tablePizzas, where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
  }

  /// Cache multiple pizzas from API into SQLite in a single transaction.
  Future<void> cachePizzas(List<PizzaModel> pizzas) async {
    if (kIsWeb) {
      _inMemoryPizzas.clear();
      _inMemoryPizzas.addAll(pizzas);
      return;
    }
    try {
      final db = await database;
      if (db == null) return;
      final batch = db.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final pizza in pizzas) {
        batch.insert(
          tablePizzas,
          _pizzaToRow(pizza, now),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  /// Clear all cached data in SQLite and re-seed defaults.
  Future<void> clearAll() async {
    _inMemoryPizzas.clear();
    _inMemoryPizzas.addAll(initialSeedPizzas);
    _inMemoryUsers.clear();
    _inMemoryUsers.addAll(initialSeedUsers);
    if (kIsWeb) return;
    try {
      final db = await database;
      if (db == null) return;
      await db.delete(tablePizzas);
      await db.delete(tableUsers);
      // Re-seed defaults
      final batch = db.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final pizza in initialSeedPizzas) {
        batch.insert(tablePizzas, _pizzaToRow(pizza, now));
      }
      for (final user in initialSeedUsers) {
        batch.insert(tableUsers, _userToRow(user));
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  /// Static helper for clearing and resetting cache.
  static Future<void> clearCache() async {
    final service = LocalDbService();
    await service.clearAll();
  }
}
