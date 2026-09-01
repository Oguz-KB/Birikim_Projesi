import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/transaction.dart';
import '../models/pending_purchase.dart';
import '../models/category.dart';
import '../models/rule_settings.dart';
import '../models/goal.dart';
import '../models/analytics_summary.dart';
import 'database_helper.dart';

class ApiClient {
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');
  static const String mockUserId = 'b2839315-a03e-49d5-9469-1ef9132e44fd';

  final http.Client client;

  ApiClient({http.Client? client}) : client = client ?? http.Client();

  Future<List<Category>> getCategories() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/categories'),
        headers: {'x-user-id': mockUserId},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Cache them for offline use
        final List<Map<String, dynamic>> cacheData = data.map((e) => {
          'id': e['id'].toString(),
          'name': e['name'].toString(),
          'is_guilty_pleasure': (e['is_guilty_pleasure'] == true || e['is_guilty_pleasure'] == 1) ? 1 : 0,
          'penalty_multiplier': e['penalty_multiplier'].toString(),
        }).toList();
        await DatabaseHelper.instance.saveCategories(cacheData);

        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('ERROR GETTING CATEGORIES: $e');
      // Offline mode: load from cache
      final cached = await DatabaseHelper.instance.getCachedCategories();
      return cached.map((c) => Category(
        id: c['id'].toString(),
        name: c['name'].toString(),
        isGuiltyPleasure: c['is_guilty_pleasure'] == 1,
        penaltyMultiplier: c['penalty_multiplier'].toString(),
      )).toList();
    }
  }

  Future<Category> createCategory(CategoryCreate category) async {
    final response = await client.post(
      Uri.parse('$baseUrl/categories/'),
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': mockUserId,
      },
      body: jsonEncode(category.toJson()),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body)['detail'] ?? 'Failed to create category';
      throw Exception(error);
    }
  }

  Future<Category> updateCategory(String categoryId, CategoryUpdate update) async {
    final response = await client.put(
      Uri.parse('$baseUrl/categories/$categoryId'),
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': mockUserId,
      },
      body: jsonEncode(update.toJson()),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body)['detail'] ?? 'Failed to update category';
      throw Exception(error);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/categories/$categoryId'),
      headers: {
        'x-user-id': mockUserId,
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete category');
    }
  }

  Future<AnalyticsSummary> getAnalyticsSummary() async {
    final response = await client.get(
      Uri.parse('$baseUrl/analytics/summary'),
      headers: {'x-user-id': mockUserId},
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return AnalyticsSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load analytics summary');
    }
  }

  Future<void> resetUserData() async {
    final response = await client.post(
      Uri.parse('$baseUrl/users/$mockUserId/reset'),
      headers: {'x-user-id': mockUserId},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reset data');
    }
  }

  Future<List<TransactionOut>> getTransactions() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/transactions/'),
        headers: {'x-user-id': mockUserId},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TransactionOut.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print('ERROR GETTING TRANSACTIONS: $e');
      return [];
    }
  }

  Future<List<PendingPurchaseOut>> getPendingPurchases() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/pending-purchases/'),
        headers: {'x-user-id': mockUserId},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PendingPurchaseOut.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load pending purchases');
      }
    } catch (e) {
      print('ERROR GETTING PENDING PURCHASES: $e');
      return [];
    }
  }

  Future<PendingPurchaseOut> resolvePendingPurchase(String purchaseId, String decision) async {
    final response = await client.post(
      Uri.parse('$baseUrl/pending-purchases/$purchaseId/resolve'),
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': mockUserId,
      },
      body: jsonEncode({'decision': decision}),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return PendingPurchaseOut.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to resolve pending purchase: ${response.statusCode}');
    }
  }

  Future<UserRuleSettings> getUserSettings() async {
    final response = await client.get(
      Uri.parse('$baseUrl/users/$mockUserId/settings'),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return UserRuleSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user settings');
    }
  }

  Future<UserRuleSettings> updateUserSettings(UserRuleSettingsUpdate update) async {
    final response = await client.put(
      Uri.parse('$baseUrl/users/$mockUserId/settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(update.toJson()),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return UserRuleSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user settings');
    }
  }

  Future<List<GoalOut>> getGoals() async {
    final response = await client.get(
      Uri.parse('$baseUrl/goals/'),
      headers: {'x-user-id': mockUserId},
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GoalOut.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load goals');
    }
  }

  Future<GoalOut> createGoal(GoalCreate goal) async {
    final response = await client.post(
      Uri.parse('$baseUrl/goals/'),
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': mockUserId,
      },
      body: jsonEncode(goal.toJson()),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 201) {
      return GoalOut.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create goal');
    }
  }

  Future<GoalOut> updateGoal(String goalId, GoalUpdate update) async {
    final response = await client.put(
      Uri.parse('$baseUrl/goals/$goalId'),
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': mockUserId,
      },
      body: jsonEncode(update.toJson()),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return GoalOut.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update goal');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/goals/$goalId'),
      headers: {
        'x-user-id': mockUserId,
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete goal');
    }
  }

  Future<TransactionOut> withdrawSavings(double amount, {String? goalId}) async {
    final Map<String, dynamic> body = {'amount': amount};
    if (goalId != null) body['goal_id'] = goalId;

    final response = await client.post(
      Uri.parse('$baseUrl/transactions/withdraw'),
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': mockUserId,
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 201) {
      return TransactionOut.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to withdraw savings: ${response.statusCode}');
    }
  }

  Future<dynamic> createTransaction(TransactionCreate tx) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/transactions/'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': mockUserId,
        },
        body: jsonEncode(tx.toJson()),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 201) {
        return TransactionOut.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 202) {
        return PendingPurchaseOut.fromJson(jsonDecode(response.body));
      } else {
        await DatabaseHelper.instance.insertQueue(tx.categoryId, tx.rawAmount);
        return {'status': 'queued', 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      await DatabaseHelper.instance.insertQueue(tx.categoryId, tx.rawAmount);
      return {'status': 'queued', 'error': e.toString()};
    }
  }

  Future<void> syncQueue() async {
    print('SYNC ÇALIŞTI');
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('SYNC IPTAL: Internet yok');
        return;
      }
    } catch (e) {
      print('Connectivity check failed in syncQueue: $e');
    }

    final queuedItems = await DatabaseHelper.instance.getQueue();
    if (queuedItems.isEmpty) return;

    print('KUYRUKTA ${queuedItems.length} İŞLEM BULUNDU, GÖNDERİLİYOR...');

    for (var item in queuedItems) {
      try {
        final tx = TransactionCreate(
          categoryId: item['category_id'],
          rawAmount: item['raw_amount'],
        );
        final response = await client.post(
          Uri.parse('$baseUrl/transactions/'),
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': mockUserId,
          },
          body: jsonEncode(tx.toJson()),
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 201 || response.statusCode == 202) {
          print('KUYRUKTAKİ İŞLEM BAŞARIYLA GÖNDERİLDİ: ${item['id']}');
          await DatabaseHelper.instance.deleteQueue(item['id']);
        } else {
          print('KUYRUK İŞLEMİ BAŞARISIZ (HTTP ${response.statusCode})');
          break; // Stop sync if server returns an error
        }
      } catch (e) {
        print('SYNC ERROR GÖNDERİRKEN: $e');
        // Stop sync on first network error
        break;
      }
    }
  }
}
