import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:salazar_advmobprog/constants.dart';
import 'package:salazar_advmobprog/screens/cart_screen.dart';
import 'package:salazar_advmobprog/screens/chat_screen.dart';
import 'package:salazar_advmobprog/screens/product_screen.dart';
import 'package:salazar_advmobprog/screens/profile_screen.dart';
import 'package:salazar_advmobprog/widgets/custom_font.dart';

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
          backgroundColor: _isOnCartScreen ? const Color(0xFF3D5A9B) : null,
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
            color: _isOnCartScreen ? Colors.white : fbLightPrimary,
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
              Navigator.push<int>(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((selectedIndex) {
                if (!mounted) return;
                if (selectedIndex == 0) {
                  setState(() {
                    _isOnCartScreen = false;
                  });
                } else if (selectedIndex == 1) {
                  setState(() {
                    _isOnCartScreen = true;
                  });
                }
              });
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
                backgroundColor: const Color(0xFFFFBE1B),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                elevation: 6,
                shape: const CircleBorder(),
                child: const Icon(Icons.message, size: 22),
              )
            : null,
      ),
    );
  }
}
