import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dish.dart';
import '../models/item_category.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  final String baseUrl = "http://172.20.10.14:8000"; // Updated to use current local IP for iOS simulator

  Future<List<ItemCategory>> getCategories(String businessId) async {
    final response = await http.get(Uri.parse('$baseUrl/businesses/$businessId/categories'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<ItemCategory> categories = body.map((dynamic item) => ItemCategory.fromJson(item)).toList();
      return categories;
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<ItemCategory> createCategory(String businessId, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/businesses/$businessId/categories'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name,
      }),
    );

    if (response.statusCode == 201) {
      return ItemCategory.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create category.');
    }
  }

  Future<List<Dish>> getItems(String categoryId) async {
    final response = await http.get(Uri.parse('$baseUrl/categories/$categoryId/items'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Dish> items = body.map((dynamic item) => Dish.fromJson(item)).toList();
      return items;
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<Dish> createItem(String categoryId, Dish item) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories/$categoryId/items'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(item.toJson()),
    );

    if (response.statusCode == 201) {
      return Dish.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create item.');
    }
  }

  Future<Dish> updateItem(Dish item) async {
    final response = await http.put(
      Uri.parse('$baseUrl/items/${item.id}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(item.toJson()),
    );

    if (response.statusCode == 200) {
      return Dish.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update item.');
    }
  }

  Future<void> deleteItem(String itemId) async {
    final response = await http.delete(Uri.parse('$baseUrl/items/$itemId'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete item.');
    }
  }

  Future<String> uploadItemImage(String itemId, XFile image) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/items/$itemId/upload-image'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final decodedData = jsonDecode(responseData);
      return decodedData['image_url'];
    } else {
      throw Exception('Failed to upload image.');
    }
  }
}
