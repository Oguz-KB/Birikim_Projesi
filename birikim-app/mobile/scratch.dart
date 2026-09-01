import 'package:http/http.dart' as http;
import 'dart:convert';
import 'lib/models/category.dart';

void main() async {
  try {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/categories'));
    print('Status: \${response.statusCode}');
    print('Body: \${response.body}');
    final List<dynamic> data = jsonDecode(response.body);
    final categories = data.map((json) {
       print('Parsing: \$json');
       return Category.fromJson(json);
    }).toList();
    print('Success: \${categories.length}');
  } catch (e) {
    print('ERROR: \$e');
  }
}
