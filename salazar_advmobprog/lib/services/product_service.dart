import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:salazar_advmobprog/constants.dart';
import 'package:salazar_advmobprog/models/product.dart';

class ProductService {
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$host/products'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"products": []}', 408),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List productsJson = data['products'] ?? [];
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else if (response.statusCode == 408) {
        throw Exception('Request timeout - Check internet');
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Network error - Check internet connection');
    } on http.ClientException catch (e) {
      throw Exception('Connection error: ${e.message}');
    } catch (e) {
      throw Exception('Error loading products: $e');
    }
  }
}