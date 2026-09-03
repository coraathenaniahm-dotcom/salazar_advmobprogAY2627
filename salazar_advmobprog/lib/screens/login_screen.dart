import 'package:flutter/material.dart';

import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final UserService userService = UserService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }

    try {
      final response = await userService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacementNamed(context, '/home', arguments: response);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString()}')));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formWidth = (MediaQuery.sizeOf(context).width * 0.86)
        .clamp(260.0, 280.0)
        .toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Transform.translate(
              offset: const Offset(0, -8),
              child: SizedBox(
                width: formWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/nubdexchange_logo.png',
                          width: 34,
                          height: 34,
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'Welcome',
                          style: TextStyle(
                            color: Color(0xFF202124),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 27),
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 11),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 11),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF394B9D),
                          disabledBackgroundColor: const Color(0xFF394B9D),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.black38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Log In',
                                style: TextStyle(fontSize: 13),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return SizedBox(
      height: 47,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Color(0xFF303039), fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6E6A75), fontSize: 11),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF6E6A75),
            fontSize: 11,
          ),
          filled: true,
          fillColor: const Color(0xFFFAF7FF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFF9A97A2), width: 1.1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFF394B9D), width: 1.4),
          ),
        ),
      ),
    );
  }
}
