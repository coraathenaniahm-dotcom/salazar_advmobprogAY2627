import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:salazar_advmobprog/constants.dart';
import 'package:salazar_advmobprog/widgets/custom_font.dart';

import 'product_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final int userId;

  const HomeScreen({super.key, this.username = '', this.userId = 1});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnCartScreen = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isOnCartScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isOnCartScreen) {
          setState(() {
            _isOnCartScreen = false;
          });
        }
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
            color: fbLightPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        body: _isOnCartScreen
            ? CartScreen(userId: widget.userId)
            : ProductScreen(
                userId: widget.userId,
                onCartPressed: () {
                  setState(() {
                    _isOnCartScreen = true;
                  });
                },
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _isOnCartScreen ? 1 : 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: fbLightPrimary,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            if (index == 0) {
              setState(() {
                _isOnCartScreen = false;
              });
            } else if (index == 1) {
              setState(() {
                _isOnCartScreen = true;
              });
            } else if (index == 2) {
              Navigator.pushNamed(context, '/profile');
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
        floatingActionButton: !_isOnCartScreen
            ? FloatingActionButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat feature coming soon')),
                  );
                },
                backgroundColor: const Color(0xFFFFBE1B),
                foregroundColor: Colors.black,
                elevation: 6,
                shape: const CircleBorder(),
                child: const Icon(Icons.message, size: 22),
              )
            : null,
      ),
    );
  }
}
