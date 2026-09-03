import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/user.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<_ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<_ProfileData> _loadProfile() async {
    final userService = UserService();
    final cartService = CartService();
    final userMap = await userService.getUserData();
    final user = userMap.isEmpty ? null : User.fromJson(userMap);

    if (user == null) {
      return _ProfileData(user: null, cart: null);
    }

    final cart = await cartService.getUserCart(user.id);
    return _ProfileData(user: user, cart: cart);
  }

  Future<void> _logout() async {
    await UserService().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FF),
      body: FutureBuilder<_ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final user = snapshot.data?.user;
          if (user == null) {
            return const Center(child: Text('No user data available'));
          }

          return SafeArea(
            child: Column(
              children: [
                Container(
                  height: 48,
                  color: const Color(0xFF394B9B),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(user.firstName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                      const Icon(Icons.settings, color: Colors.white, size: 23),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: const Color(0xFFE7DDF4),
                                backgroundImage: user.image.isNotEmpty ? NetworkImage(user.image) : null,
                                child: user.image.isEmpty
                                    ? Text('${user.firstName[0]}${user.lastName[0]}', style: const TextStyle(color: Color(0xFF394B9B), fontSize: 25, fontWeight: FontWeight.bold))
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Text('${user.firstName} ${user.lastName}', style: const TextStyle(color: Colors.black87, fontSize: 21, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 5),
                              Text('@${user.username}', style: const TextStyle(color: Color(0xFFEAB526), fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
                          child: Column(
                            children: [
                              _InfoRow(icon: Icons.mail_outline, label: 'Email', value: user.email),
                              const Divider(height: 1, indent: 14, endIndent: 14),
                              const _InfoRow(icon: Icons.accessibility_new, label: 'Gender', value: 'female'),
                              const Divider(height: 1, indent: 14, endIndent: 14),
                              _InfoRow(icon: Icons.badge_outlined, label: 'User ID', value: '#${user.id}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, size: 20),
                            label: const Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6355),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.shopping_bag_outlined, color: Colors.grey),
            Icon(Icons.shopping_cart, color: Colors.grey),
            Icon(Icons.person, color: Color(0xFF394B9B)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
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
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFBE1B), size: 21),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileData {
  final User? user;
  final Cart? cart;

  _ProfileData({required this.user, required this.cart});
}

