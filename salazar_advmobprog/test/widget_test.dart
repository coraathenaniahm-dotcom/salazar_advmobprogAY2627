import 'package:flutter_test/flutter_test.dart';

import 'package:salazar_advmobprog/models/cart.dart';

void main() {
  test('cart parser accepts dummyjson discountedPrice response', () {
    final cart = Cart.fromJson({
      'id': 209,
      'products': [
        {
          'id': 1,
          'title': 'Essence Mascara Lash Princess',
          'price': 9.99,
          'quantity': 1,
          'total': 9.99,
          'discountPercentage': 10.48,
          'discountedPrice': 9,
          'thumbnail': 'https://example.com/thumb.jpg',
        },
      ],
      'total': 9.99,
      'discountedTotal': 9,
      'userId': 1,
      'totalProducts': 1,
      'totalQuantity': 1,
    });

    expect(cart.products.first.discountedTotal, 9.0);
    expect(cart.discountedTotal, 9.0);
  });
}