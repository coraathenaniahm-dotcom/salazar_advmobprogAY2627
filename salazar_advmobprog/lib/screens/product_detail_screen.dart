import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:salazar_advmobprog/models/product.dart';
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
                  onPressed: _showCartUnchangedMessage,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF394B9D),
                    foregroundColor:
                        Colors.white,
                    minimumSize:
                        Size.fromHeight(50.h),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12.r),
                    ),
                  ),
                  child: CustomText(
                    text: 'Add to Cart',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
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

  void _showCartUnchangedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item was not added to the cart')),
    );
  }

}