import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salazar_advmobprog/models/cart.dart';
import 'package:salazar_advmobprog/services/cart_service.dart';
import 'package:salazar_advmobprog/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    'userData': '{"id":42,"username":"cheska"}',
  });
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

  test('user cart response selects the cart matching the requested user', () {
    final cart = Cart.fromUserCartsResponse({
      'carts': [
        {
          'id': 1,
          'products': [],
          'userId': 2,
          'total': 0,
          'discountedTotal': 0,
          'totalProducts': 0,
          'totalQuantity': 0,
        },
        {
          'id': 42,
          'products': [
            {
              'id': 3,
              'title': 'Emily product',
              'price': 25,
              'quantity': 2,
              'total': 50,
              'discountPercentage': 0,
              'discountedTotal': 50,
              'thumbnail': '',
            },
          ],
          'userId': 42,
          'total': 50,
          'discountedTotal': 50,
          'totalProducts': 1,
          'totalQuantity': 2,
        },
      ],
      'total': 2,
    }, 42);

    expect(cart?.userId, 42);
    expect(cart?.products.single.title, 'Emily product');
  });

  test('added products merge with the DummyJSON cart without replacing it', () {
    final dummyJsonCart = Cart.fromJson({
      'id': 1,
      'products': [
        {
          'id': 10,
          'title': 'DummyJSON product',
          'price': 12,
          'quantity': 1,
          'total': 12,
          'discountPercentage': 0,
          'discountedTotal': 12,
          'thumbnail': '',
        },
      ],
      'total': 12,
      'discountedTotal': 12,
      'userId': 1,
      'totalProducts': 1,
      'totalQuantity': 1,
    });
    final localAddition = Cart.fromJson({
      'id': 0,
      'products': [
        {
          'id': 20,
          'title': 'Added product',
          'price': 5,
          'quantity': 2,
          'total': 10,
          'discountPercentage': 0,
          'discountedTotal': 10,
          'thumbnail': '',
        },
      ],
      'total': 10,
      'discountedTotal': 10,
      'userId': 1,
      'totalProducts': 1,
      'totalQuantity': 2,
    });

    final visibleCart = dummyJsonCart.mergedWith(localAddition);

    expect(visibleCart.products.map((item) => item.title), [
      'DummyJSON product',
      'Added product',
    ]);
    expect(visibleCart.totalQuantity, 3);
    expect(visibleCart.total, 22);
  });

  test('firebase profile mapper keeps custom username and profile data', () {
    final user = UserService.userFromFirebaseProfile(
      uid: 'abc123',
      email: 'cheska@example.com',
      displayName: 'cheska',
      profileData: {
        'firstName': 'Cheska',
        'lastName': 'Salazar',
        'username': 'cheska',
        'image': '',
      },
    );

    expect(user.username, 'cheska');
    expect(user.email, 'cheska@example.com');
    expect(user.firstName, 'Cheska');
    expect(user.lastName, 'Salazar');
    expect(user.id, isA<int>());
  });

  test('cart resolves to current session user instead of default user 1', () async {
    final resolvedId = await CartService.resolveUserIdForCurrentUser(0);
    expect(resolvedId, 42);

    final resolvedIdFromDefaultPlaceholder = await CartService.resolveUserIdForCurrentUser(1);
    expect(resolvedIdFromDefaultPlaceholder, 42);
  });

  test('cart reload keeps locally saved products for the logged-in user', () async {
    SharedPreferences.setMockInitialValues({
      'userData': '{"id":42,"username":"emily"}',
      'cart_user_42':
          '{"id":7,"products":[{"id":1,"title":"Product","price":10,"quantity":2,"total":20,"discountPercentage":0,"discountedTotal":20,"thumbnail":""}],"total":20,"discountedTotal":20,"userId":42,"totalProducts":1,"totalQuantity":2}',
    });

    final cart = await CartService().getUserCart(1);

    expect(cart.userId, 42);
    expect(cart.products, hasLength(1));
    expect(cart.products.first.quantity, 2);
  });
}