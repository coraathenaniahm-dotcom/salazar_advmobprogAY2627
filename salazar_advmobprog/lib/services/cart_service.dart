import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';

class CartService {
  static const int defaultUserId = 1;

  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  Future<Cart> getUserCart(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List carts = data['carts'] ?? [];
      if (carts.isNotEmpty) {
        return Cart.fromJson(carts.first);
      } else {
        throw Exception('No cart found for user');
      }
    } else {
      throw Exception('Failed to load cart');
    }
  }

  Future<Cart> addToCart(
    int productId,
    int quantity, {
    int userId = defaultUserId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$host/carts/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'products': [
            {'id': productId, 'quantity': quantity}
          ]
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{}', 408),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Cart.fromJson(data);
      } else if (response.statusCode == 408) {
        throw Exception('Request timeout - Check internet');
      } else {
        throw Exception('Failed to add to cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding to cart: $e');
    }
  }
}