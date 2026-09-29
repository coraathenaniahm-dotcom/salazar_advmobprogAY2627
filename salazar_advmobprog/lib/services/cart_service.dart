import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart.dart';
import 'product_service.dart';

class CartService {
  static const int defaultUserId = 1;

  String _cartKey(int userId) => 'cart_user_$userId';

  Future<Cart> getUserCart(int userId) async {
    final resolvedUserId = userId > 0 ? userId : defaultUserId;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cartKey(resolvedUserId));

    if (raw == null || raw.isEmpty) {
      return _emptyCart(resolvedUserId);
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return _emptyCart(resolvedUserId);
    }

    return Cart.fromJson(decoded);
  }

  Future<Cart> addToCart(
    int productId,
    int quantity, {
    int userId = defaultUserId,
  }) async {
    final resolvedUserId = userId > 0 ? userId : defaultUserId;
    final cart = await getUserCart(resolvedUserId);

    final allProducts = await ProductService().getAllProducts();
    final product = allProducts.firstWhere(
      (item) => item.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    final existingIndex = cart.products.indexWhere((item) => item.id == productId);
    final updatedProducts = [...cart.products];

    if (existingIndex >= 0) {
      final current = updatedProducts[existingIndex];
      updatedProducts[existingIndex] = CartProduct(
        id: current.id,
        title: current.title,
        price: current.price,
        quantity: current.quantity + quantity,
        total: current.price * (current.quantity + quantity),
        discountPercentage: current.discountPercentage,
        discountedTotal: current.price * (1 - (current.discountPercentage / 100)) * (current.quantity + quantity),
        thumbnail: current.thumbnail,
      );
    } else {
      final discountedPrice = product.price * (1 - (product.discountPercentage / 100));
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

    final newCart = Cart(
      id: cart.id == 0 ? DateTime.now().millisecondsSinceEpoch : cart.id,
      products: updatedProducts,
      total: updatedProducts.fold<double>(0, (sum, item) => sum + item.total),
      discountedTotal: updatedProducts.fold<double>(
        0,
        (sum, item) => sum + item.discountedTotal,
      ),
      userId: resolvedUserId,
      totalProducts: updatedProducts.length,
      totalQuantity: updatedProducts.fold<int>(0, (sum, item) => sum + item.quantity),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey(resolvedUserId), jsonEncode(newCart.toJson()));

    return newCart;
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