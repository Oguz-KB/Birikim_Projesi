import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../lib/services/api_client.dart';
import '../lib/services/database_helper.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Clear database before each test
    final db = await DatabaseHelper.instance.database;
    await db.delete('offline_queue');
  });

  test('Offline Queue: syncQueue flushes local queue and sends to backend', () async {
    // 1. Insert a mock item into the local queue manually
    final mockCategoryId = 'mock-cat-id';
    final mockRawAmount = '150.50';
    await DatabaseHelper.instance.insertQueue(mockCategoryId, mockRawAmount);

    // Verify it's in the queue
    var queue = await DatabaseHelper.instance.getQueue();
    expect(queue.length, 1);
    expect(queue.first['category_id'], mockCategoryId);

    bool apiCalled = false;

    // 2. Mock the HTTP Client to return a successful response (201)
    final mockClient = MockClient((request) async {
      apiCalled = true;
      expect(request.url.path, '/transactions/');
      expect(request.headers['x-user-id'], isNotNull);
      
      final body = jsonDecode(request.body);
      expect(body['category_id'], mockCategoryId);
      expect(body['raw_amount'], mockRawAmount);

      return http.Response(jsonEncode({
        'id': 'mock-tx-id',
        'user_id': ApiClient.mockUserId,
        'category_id': mockCategoryId,
        'raw_amount': mockRawAmount,
        'self_tax_amount': '15.05',
        'roundup_amount': '0',
        'total_diverted': '15.05',
        'rule_settings_id': 'mock-rule-id',
        'created_at': DateTime.now().toIso8601String()
      }), 201);
    });

    final apiClient = ApiClient(client: mockClient);

    // 3. Call syncQueue()
    await apiClient.syncQueue();

    // 4. Verify API was called
    expect(apiCalled, true);

    // 5. Verify local queue is empty
    queue = await DatabaseHelper.instance.getQueue();
    expect(queue.length, 0);
  });
}
