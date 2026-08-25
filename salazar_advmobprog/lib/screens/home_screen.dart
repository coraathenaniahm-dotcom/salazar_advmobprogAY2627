import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:salazar_advmobprog/constants.dart';
import 'package:salazar_advmobprog/widgets/custom_font.dart';

import 'product_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnCartScreen = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: WillPopScope(
        onWillPop: () async {
          if (_isOnCartScreen) {
            setState(() {
              _isOnCartScreen = false;
            });
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 2,
            leading: _isOnCartScreen
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _isOnCartScreen = false;
                      });
                    },
                  )
                : null,
            title: CustomText(
              text: _isOnCartScreen ? 'Cart' : 'Shop',
              fontSize: 20.sp,
              color: FB_LIGHT_PRIMARY,
              fontWeight: FontWeight.w800,
            ),
            actions: [
              if (!_isOnCartScreen)
                IconButton(
                  icon: Icon(Icons.shopping_cart, size: 24.sp),
                  onPressed: () {
                    setState(() {
                      _isOnCartScreen = true;
                    });
                  },
                ),
              if (!_isOnCartScreen)
                IconButton(
                  icon: Icon(Icons.settings, size: 24.sp),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/settings'),
                ),
            ],
          ),
          body: _isOnCartScreen ? const CartScreen() : ProductScreen(
            onCartPressed: () {
              setState(() {
                _isOnCartScreen = true;
              });
            },
          ),
          floatingActionButton: !_isOnCartScreen
              ? FloatingActionButton(
                  onPressed: () {
                    // Chat functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat feature coming soon')),
                    );
                  },
                  child: const Icon(Icons.chat),
                )
              : null,
        ),
      ),
    );
  }
}