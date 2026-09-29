import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:salazar_advmobprog/models/product.dart';
import 'package:salazar_advmobprog/services/cart_service.dart';
import 'package:salazar_advmobprog/widgets/custom_text.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final int userId;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.userId = 1,
  });

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isAddingToCart = false;

  final CartService _cartService = CartService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText(
          text: 'Product Details',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  widget.product.thumbnail,
                  width: double.infinity,
                  height: 300.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 300.h,
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.image,
                        size: 48.sp,
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20.h),

              CustomText(
                text: widget.product.title,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),

              SizedBox(height: 12.h),

              CustomText(
                text:
                    '\$${widget.product.price.toStringAsFixed(2)}',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),

              SizedBox(height: 12.h),

              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  CustomText(
                    text:
                        '${widget.product.rating} • ${widget.product.stock} in stock',
                    fontSize: 14.sp,
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              CustomText(
                text: 'Description',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),

              SizedBox(height: 8.h),

              CustomText(
                text: widget.product.description,
                fontSize: 13.sp,
              ),

              SizedBox(height: 20.h),

              CustomText(
                text:
                    'Category: ${widget.product.category}',
                fontSize: 13.sp,
              ),

              SizedBox(height: 8.h),

              CustomText(
                text:
                    'Brand: ${widget.product.brand}',
                fontSize: 13.sp,
              ),

              SizedBox(height: 20.h),

              Row(
                children: [
                  CustomText(
                    text: 'Quantity:',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),

                  SizedBox(width: 12.w),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                      ),
                      borderRadius:
                          BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1
                              ? () {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              : null,
                          icon: const Icon(
                            Icons.remove,
                          ),
                          iconSize: 18.sp,
                        ),

                        SizedBox(
                          width: 40.w,
                          child: Center(
                            child: CustomText(
                              text: '$_quantity',
                              fontSize: 14.sp,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed:
                              _quantity <
                                      widget.product.stock
                                  ? () {
                                      setState(() {
                                        _quantity++;
                                      });
                                    }
                                  : null,
                          icon: const Icon(
                            Icons.add,
                          ),
                          iconSize: 18.sp,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isAddingToCart
                      ? null
                      : _addToCart,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF394B9D),
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF394B9D),
                    minimumSize:
                        Size.fromHeight(50.h),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isAddingToCart
                      ? SizedBox(
                          height: 24.h,
                          width: 24.w,
                          child:
                              const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : CustomText(
                          text: 'Add to Cart',
                          fontSize: 16.sp,
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    setState(() {
      _isAddingToCart = true;
    });

    try {
      await _cartService.addToCart(
        widget.product.id,
        _quantity,
        userId: widget.userId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text:
                '${widget.product.title} added to cart',
            fontSize: 14.sp,
            color: Colors.white,
          ),
          duration:
              const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _quantity = 1;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text: e.toString(),
            fontSize: 14.sp,
            color: Colors.white,
          ),
          duration:
              const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }
}