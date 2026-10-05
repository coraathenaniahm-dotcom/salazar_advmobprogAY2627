import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/cart.dart';
import 'product_service.dart';

class CartService {
  static const int defaultUserId = 1;

  static Future<int> resolveUserIdForCurrentUser(int requestedUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawUserData = prefs.getString('userData');
    Map<String, dynamic> userData = {};

    if (rawUserData != null && rawUserData.isNotEmpty) {
      final decoded = jsonDecode(rawUserData);
      if (decoded is Map<String, dynamic>) {
        userData = decoded;
      } else if (decoded is Map) {
        userData = Map<String, dynamic>.from(decoded);
      }
    }

    final savedId = userData['id'];
    if (savedId is int && savedId > 0) {
      if (requestedUserId == defaultUserId && savedId != defaultUserId) {
        return savedId;
      }
      return savedId;
    }

    if (savedId is String) {
      final parsedId = int.tryParse(savedId);
      if (parsedId != null && parsedId > 0) {
        if (requestedUserId == defaultUserId && parsedId != defaultUserId) {
          return parsedId;
        }
        return parsedId;
      }
    }

    if (requestedUserId > 0 && requestedUserId != defaultUserId) {
      return requestedUserId;
    }

    final username = (userData['username'] ?? '').toString();
    if (username.isNotEmpty) {
      return username.hashCode.abs();
    }

    return defaultUserId;
  }

  String _cartKey(int userId) => 'cart_user_$userId';
  String _additionsKey(int userId) => 'cart_additions_user_$userId';

  Future<Cart> getUserCart(int userId) async {
    final resolvedUserId = await resolveUserIdForCurrentUser(userId);
    final prefs = await SharedPreferences.getInstance();
    Cart? baseCart;

    try {
      final response = await http.get(
        Uri.parse('$host/carts/user/$resolvedUserId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"products": []}', 408),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final cart = Cart.fromUserCartsResponse(decoded, resolvedUserId);
          if (cart != null) {
            baseCart = cart;
            await prefs.setString(
              _cartKey(resolvedUserId),
              jsonEncode(cart.toJson()),
            );
          }
        }
      }
    } on SocketException {
      // Fall back to local cart data when offline.
    } on http.ClientException {
      // Fall back to local cart data when the host is unavailable.
    }

    if (baseCart == null) {
      final cachedCart = prefs.getString(_cartKey(resolvedUserId));
      if (cachedCart != null && cachedCart.isNotEmpty) {
        final decoded = jsonDecode(cachedCart);
        if (decoded is Map<String, dynamic>) {
          final cart = Cart.fromJson(decoded);
          if (cart.userId == resolvedUserId) baseCart = cart;
        }
      }
    }

    final additionsJson = prefs.getString(_additionsKey(resolvedUserId));
    if (additionsJson != null && additionsJson.isNotEmpty) {
      final decoded = jsonDecode(additionsJson);
      if (decoded is Map<String, dynamic>) {
        final additions = Cart.fromJson(decoded);
        if (additions.userId == resolvedUserId) {
          baseCart = (baseCart ?? _emptyCart(resolvedUserId)).mergedWith(
            additions,
          );
        }
      }
    }

    return baseCart ?? _emptyCart(resolvedUserId);
  }

  Future<Cart> addToCart(
    int productId,
    int quantity, {
    int userId = defaultUserId,
  }) async {
    final resolvedUserId = await resolveUserIdForCurrentUser(userId);
    final currentCart = await getUserCart(resolvedUserId);
    final allProducts = await ProductService().getAllProducts();
    final product = allProducts.firstWhere(
      (item) => item.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );
    final prefs = await SharedPreferences.getInstance();
    final additionsJson = prefs.getString(_additionsKey(resolvedUserId));
    var additions = _emptyCart(resolvedUserId);
    if (additionsJson != null && additionsJson.isNotEmpty) {
      final decoded = jsonDecode(additionsJson);
      if (decoded is Map<String, dynamic>) {
        final savedAdditions = Cart.fromJson(decoded);
        if (savedAdditions.userId == resolvedUserId) {
          additions = savedAdditions;
        }
      }
    }

    final updatedAdditions = _addProduct(
      additions.products,
      product,
      quantity,
    );
    final additionsCart = _createCart(
      additions.id,
      updatedAdditions,
      resolvedUserId,
    );
    await prefs.setString(
      _additionsKey(resolvedUserId),
      jsonEncode(additionsCart.toJson()),
    );

    try {
      await http.post(
        Uri.parse('$host/carts/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': resolvedUserId,
          'products': [
            {'id': productId, 'quantity': quantity},
          ],
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"products": []}', 408),
      );
    } on SocketException {
      // Fall back to local cart when offline.
    } on http.ClientException {
      // Fall back to local cart when the host is unavailable.
    }

    final addedItem = _createCart(
      0,
      _addProduct(const [], product, quantity),
      resolvedUserId,
    );
    return currentCart.mergedWith(addedItem);
  }

  List<CartProduct> _addProduct(
    List<CartProduct> products,
    dynamic product,
    int quantity,
  ) {
    final updatedProducts = [...products];
    final existingIndex = updatedProducts.indexWhere(
      (item) => item.id == product.id,
    );

    if (existingIndex >= 0) {
      final current = updatedProducts[existingIndex];
      final updatedQuantity = current.quantity + quantity;
      updatedProducts[existingIndex] = CartProduct(
        id: current.id,
        title: current.title,
        price: current.price,
        quantity: updatedQuantity,
        total: current.price * updatedQuantity,
        discountPercentage: current.discountPercentage,
        discountedTotal: current.price *
            (1 - current.discountPercentage / 100) *
            updatedQuantity,
        thumbnail: current.thumbnail,
      );
    } else {
      final discountedPrice =
          product.price * (1 - product.discountPercentage / 100);
      updatedProducts.add(
        CartProduct(
          id: product.id,
          title: product.title,
          price: product.price,
          quantity: quantity,
          total: product.price * quantity,
          discountPercentage: product.discountPercentage,
          discountedTotal: discountedPrice * quantity,
          thumbnail: product.thumbnail,
        ),
      );
    }

    return updatedProducts;
  }

  Cart _createCart(int cartId, List<CartProduct> products, int userId) {
    return Cart(
      id: cartId,
      products: products,
      total: products.fold<double>(0, (sum, item) => sum + item.total),
      discountedTotal: products.fold<double>(
        0,
        (sum, item) => sum + item.discountedTotal,
      ),
      userId: userId,
      totalProducts: products.length,
      totalQuantity: products.fold<int>(0, (sum, item) => sum + item.quantity),
    );
  }

  Cart _emptyCart(int userId) {
    return Cart(
      id: 0,
      products: const [],
      total: 0,
      discountedTotal: 0,
      userId: userId,
      totalProducts: 0,
      totalQuantity: 0,
    );
  }
}