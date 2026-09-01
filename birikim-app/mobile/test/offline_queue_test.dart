import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mobile/services/database_helper.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Offline Queue: insertQueue adds to local database', () async {
    // We can't easily mock Connectivity() without extra packages, 
    // but we can test the database layer works as an offline queue.
    await DatabaseHelper.instance.insertQueue('mock-cat-id', '150.50');
    
    final queue = await DatabaseHelper.instance.getQueue();
    expect(queue.isNotEmpty, true);
    
    final lastItem = queue.last;
    expect(lastItem['category_id'], 'mock-cat-id');
    expect(lastItem['raw_amount'], '150.50');
    
    // Clean up
    await DatabaseHelper.instance.deleteQueue(lastItem['id']);
  });
}
