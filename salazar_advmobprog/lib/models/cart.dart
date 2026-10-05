class Cart {
  final int id;
  final List<CartProduct> products;
  final double total;
  final double discountedTotal;
  final int userId;
  final int totalProducts;
  final int totalQuantity;

  Cart({
    required this.id,
    required this.products,
    required this.total,
    required this.discountedTotal,
    required this.userId,
    required this.totalProducts,
    required this.totalQuantity,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? 0,
      products: (json['products'] as List?)
              ?.map((e) => CartProduct.fromJson(e))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountedTotal:
          (json['discountedTotal'] as num?)?.toDouble() ??
              (json['discountedPrice'] as num?)?.toDouble() ??
              0.0,
      userId: json['userId'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalQuantity: json['totalQuantity'] ?? 0,
    );
  }

  static Cart? fromUserCartsResponse(
    Map<String, dynamic> json,
    int userId,
  ) {
    final carts = json['carts'];
    if (carts is List) {
      for (final item in carts) {
        if (item is Map) {
          final cartJson = Map<String, dynamic>.from(item);
          final cartUserId = int.tryParse('${cartJson['userId']}');
          if (cartUserId == userId) return Cart.fromJson(cartJson);
        }
      }
      return null;
    }

    if (json['products'] is List) return Cart.fromJson(json);
    return null;
  }

  Cart mergedWith(Cart additions) {
    final mergedProducts = [...products];

    for (final addition in additions.products) {
      final index = mergedProducts.indexWhere((item) => item.id == addition.id);
      if (index < 0) {
        mergedProducts.add(addition);
        continue;
      }

      final current = mergedProducts[index];
      final quantity = current.quantity + addition.quantity;
      mergedProducts[index] = CartProduct(
        id: current.id,
        title: current.title,
        price: current.price,
        quantity: quantity,
        total: current.price * quantity,
        discountPercentage: current.discountPercentage,
        discountedTotal:
            current.price * (1 - current.discountPercentage / 100) * quantity,
        thumbnail: current.thumbnail,
      );
    }

    return Cart(
      id: id,
      products: mergedProducts,
      total: mergedProducts.fold<double>(0, (sum, item) => sum + item.total),
      discountedTotal: mergedProducts.fold<double>(
        0,
        (sum, item) => sum + item.discountedTotal,
      ),
      userId: userId,
      totalProducts: mergedProducts.length,
      totalQuantity: mergedProducts.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products': products.map((e) => e.toJson()).toList(),
      'total': total,
      'discountedTotal': discountedTotal,
      'userId': userId,
      'totalProducts': totalProducts,
      'totalQuantity': totalQuantity,
    };
  }
}

class CartProduct {
  final int id;
  final String title;
  final double price;
  final int quantity;
  final double total;
  final double discountPercentage;
  final double discountedTotal;
  final String thumbnail;

  CartProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.total,
    required this.discountPercentage,
    required this.discountedTotal,
    required this.thumbnail,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      discountedTotal:
          (json['discountedTotal'] as num?)?.toDouble() ??
              (json['discountedPrice'] as num?)?.toDouble() ??
              0.0,
      thumbnail: json['thumbnail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'quantity': quantity,
      'total': total,
      'discountPercentage': discountPercentage,
      'discountedTotal': discountedTotal,
      'thumbnail': thumbnail,
    };
  }
}