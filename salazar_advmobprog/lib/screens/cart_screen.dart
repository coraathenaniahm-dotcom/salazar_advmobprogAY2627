import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:salazar_advmobprog/models/cart.dart';
import 'package:salazar_advmobprog/services/cart_service.dart';
import 'package:salazar_advmobprog/widgets/custom_text.dart';

class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({super.key, this.userId = 1});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<Cart> cartFuture;
  final cartService = CartService();
  late Map<int, int> quantities;

  @override
  void initState() {
    super.initState();
    quantities = {};
    _loadCart();
  }

  void _loadCart() {
    cartFuture = cartService.getUserCart(widget.userId).then((cart) {
      for (var product in cart.products) {
        quantities[product.id] = product.quantity;
      }
      return cart;
    });
  }

  void _updateQuantity(int productId, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        quantities[productId] = newQuantity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FutureBuilder<Cart>(
        future: cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: CustomText(
                text: 'Error: ${snapshot.error}',
                fontSize: 14.sp,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.products.isEmpty) {
            return Center(
              child: CustomText(text: 'Cart is empty', fontSize: 16.sp),
            );
          }

          final cart = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  itemCount: cart.products.length,
                  itemBuilder: (context, index) {
                    final cartProduct = cart.products[index];
                    final currentQty =
                        quantities[cartProduct.id] ?? cartProduct.quantity;
                    final discountPercent = cartProduct.discountPercentage;
                    final originalPrice = cartProduct.price;
                    final discountedPrice =
                        originalPrice * (1 - (discountPercent / 100));

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.2),
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12.r),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 70.w,
                                height: 70.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.r),
                                  color: Colors.grey[100],
                                ),
                                child: Image.network(
                                  cartProduct.thumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.image);
                                  },
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomText(
                                      text: cartProduct.title,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 6.h),
                                    CustomText(
                                      text:
                                          '\$${discountedPrice.toStringAsFixed(2)}',
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFFA500),
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        if (discountPercent > 0)
                                          CustomText(
                                            text:
                                                '${discountPercent.toStringAsFixed(0)}% off • ',
                                            fontSize: 10.sp,
                                            color: Colors.grey[600],
                                          ),
                                        CustomText(
                                          text:
                                              '-\$${(originalPrice - discountedPrice).toStringAsFixed(2)} total',
                                          fontSize: 10.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () => _updateQuantity(
                                      cartProduct.id,
                                      currentQty + 1,
                                    ),
                                    child: Container(
                                      width: 32.w,
                                      height: 32.h,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFC107),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.add,
                                        size: 18.sp,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  CustomText(
                                    text: currentQty.toString(),
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  SizedBox(height: 6.h),
                                  GestureDetector(
                                    onTap: () => _updateQuantity(
                                      cartProduct.id,
                                      currentQty - 1,
                                    ),
                                    child: Container(
                                      width: 32.w,
                                      height: 32.h,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.remove,
                                        size: 18.sp,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          text: 'Subtotal:',
                          fontSize: 13.sp,
                          color: Colors.grey,
                        ),
                        CustomText(
                          text: '\$${cart.total.toStringAsFixed(2)}',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    if (cart.total != cart.discountedTotal) ...[
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            text: 'Discount:',
                            fontSize: 13.sp,
                            color: Colors.grey,
                          ),
                          CustomText(
                            text:
                                '-\$${(cart.total - cart.discountedTotal).toStringAsFixed(2)}',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFA500),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          text: 'Total:',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        CustomText(
                          text: '\$${cart.discountedTotal.toStringAsFixed(2)}',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFA500),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: CustomText(
                        text: 'Confirm Order',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}