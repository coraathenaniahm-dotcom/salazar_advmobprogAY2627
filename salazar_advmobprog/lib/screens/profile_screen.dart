import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  late Future<_ProfileData> _profileFuture;
  String _profileName = '';
  String _profileUsername = '';

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<_ProfileData> _loadProfile() async {
    // Load the saved user and their cart data.
    final userService = UserService();
    final cartService = CartService();
    final userMap = await userService.getUserData();
    final loginType = await userService.getLoginType();
    User? user = userMap.isEmpty ? null : User.fromJson(userMap);

    if (user == null && loginType == UserService.firebaseLoginType) {
      final firebaseUser = userService.firebaseAuth.currentUser;
      if (firebaseUser != null) {
        final nameParts = (firebaseUser.displayName ?? '').split(' ');
        user = User(
          id: 0,
          firstName: nameParts.isEmpty ? '' : nameParts.first,
          lastName: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
          username: firebaseUser.displayName ?? firebaseUser.email ?? '',
          email: firebaseUser.email ?? '',
          image: firebaseUser.photoURL ?? '',
        );
      }
    }

    if (user == null) {
      return _ProfileData(user: null, cart: null, loginType: loginType);
    }

    if (mounted) {
      setState(() {
        _profileName = user?.firstName ?? '';
        _profileUsername = user?.username ?? '';
      });
    }

    final cart = await cartService.getUserCart(user.id);
    return _ProfileData(user: user, cart: cart, loginType: loginType);
  }

  Future<void> _logout() async {
    // Clear the local session before returning to login.
    await UserService().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _updateUsername(User user) async {
    var enteredUsername = user.username;
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update username'),
        content: TextFormField(
          autofocus: true,
          initialValue: user.username,
          onChanged: (value) => enteredUsername = value,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, enteredUsername.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (username == null || username.isEmpty) return;
    try {
      await UserService().updateUsername(username: username);
      if (!mounted) return;
      setState(() {
        _profileUsername = username;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update username: $error')),
        );
      }
    }
  }

  Future<void> _changePassword(User user) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, [
              currentController.text,
              newController.text,
              confirmController.text,
            ]),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (values == null || values[1].length < 6 || values[1] != values[2]) {
      if (mounted && values != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check the new password fields')),
        );
      }
      return;
    }

    try {
      await UserService().resetPasswordFromCurrentPassword(
        currentPassword: values[0],
        newPassword: values[1],
        email: user.email,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not change password: $error')),
        );
      }
    }
  }

  Future<void> _deleteAccount(User user) async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    final password = passwordController.text;

    if (confirmed != true) return;
    try {
      await UserService().deleteAccount(email: user.email, password: password);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete account: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the active theme for profile surfaces and text.
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5A9B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _profileName.isEmpty ? 'Profile' : _profileName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          // Return to the previous page.
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            // Open light and dark mode settings.
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    child: Column(
                      children: [
                        // User identity card.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
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
                              Text('${user.firstName} ${user.lastName}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 21, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 5),
                              Text(
                                '@${_profileUsername.isEmpty ? user.username : _profileUsername}',
                                style: const TextStyle(
                                  color: Color(0xFFEAB526),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        // User details card.
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(17)),
                          child: Column(
                            children: [
                              _InfoRow(icon: Icons.mail_outline, label: 'Email', value: user.email),
                              const Divider(height: 1, indent: 14, endIndent: 14),
                              const _InfoRow(icon: Icons.accessibility_new, label: 'Gender', value: 'female'),
                              const Divider(height: 1, indent: 14, endIndent: 14),
                              _InfoRow(icon: Icons.badge_outlined, label: 'User ID', value: '#${user.id}'),
                              const Divider(height: 1, indent: 14, endIndent: 14),
                              _InfoRow(
                                icon: Icons.login,
                                label: 'Login type',
                                value: snapshot.data!.loginType ==
                                        UserService.firebaseLoginType
                                    ? 'Firebase'
                                    : 'DummyJSON',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        _ProfileAction(
                          icon: Icons.edit_outlined,
                          label: 'Update username',
                          onPressed: () => _updateUsername(user),
                        ),
                        _ProfileAction(
                          icon: Icons.lock_outline,
                          label: 'Change password',
                          onPressed: () => _changePassword(user),
                        ),
                        _ProfileAction(
                          icon: Icons.delete_outline,
                          label: 'Delete account',
                          color: Colors.red,
                          onPressed: () => _deleteAccount(user),
                        ),
                        const SizedBox(height: 12),
                        // End the current session.
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, size: 20),
                            label: const Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6355),
                              foregroundColor: Theme.of(context).colorScheme.onError,
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF394B9B),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // Return the selected destination to HomeScreen.
          if (index == 0 || index == 1) {
            Navigator.pop(context, index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // Placeholder for the chat action.
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat feature coming soon')),
          );
        },
        backgroundColor: const Color(0xFFFFBE1B),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
    // Display one labeled profile detail.
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

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;

  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onPressed,
    );
  }
}

class _ProfileData {
  final User? user;
  final Cart? cart;
  final String loginType;

  _ProfileData({required this.user, required this.cart, required this.loginType});
}

