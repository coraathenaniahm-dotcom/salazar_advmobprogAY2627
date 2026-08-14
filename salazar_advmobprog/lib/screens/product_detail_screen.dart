import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:salazar_advmobprog/models/product.dart';
import 'package:salazar_advmobprog/widgets/custom_text.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  product.thumbnail,
                  width: double.infinity,
                  height: 300.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 300.h,
                    color: Colors.grey.shade300,
                    child: Icon(
                      Icons.image,
                      size: 48.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              CustomText(
                text: product.title,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 12.h),
              CustomText(
                text: '\$${product.price.toStringAsFixed(2)}',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20.sp),
                  SizedBox(width: 8.w),
                  CustomText(
                    text: '${product.rating} • ${product.stock} in stock',
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
                text: product.description,
                fontSize: 13.sp,
              ),
              SizedBox(height: 20.h),
              CustomText(
                text: 'Category: ${product.category}',
                fontSize: 13.sp,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: 'Brand: ${product.brand}',
                fontSize: 13.sp,
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: CustomText(
                          text: '${product.title} added to cart',
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
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
}
