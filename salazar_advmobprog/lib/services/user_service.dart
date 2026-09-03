import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  // Logs in a user and save session
  Future<User> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$host/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"message": "Request timeout"}', 408),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final user = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        // Keep the login state and user details for later use.
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userData', jsonEncode(user.toJson()));

        return user;
      } else if (response.statusCode == 408) {
        throw Exception('Request timeout - Check internet');
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Network error - Check internet connection');
    } on http.ClientException catch (e) {
      throw Exception('Connection error: ${e.message}');
    } catch (e) {
      throw Exception('Error logging in: $e');
    }
  }

  // Gets one user from the server by ID.
  Future<User> getUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$host/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{}', 408),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return User.fromJson(data);
      } else if (response.statusCode == 408) {
        throw Exception('Request timeout - Check internet');
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Network error - Check internet connection');
    } on http.ClientException catch (e) {
      throw Exception('Connection error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // Gets all users from the server.
  Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$host/users'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"users": []}', 408),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List usersJson = data['users'] ?? [];
        return usersJson.map((json) => User.fromJson(json)).toList();
      } else if (response.statusCode == 408) {
        throw Exception('Request timeout - Check internet');
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Network error - Check internet connection');
    } on http.ClientException catch (e) {
      throw Exception('Connection error: ${e.message}');
    } catch (e) {
      throw Exception('Error loading users: $e');
    }
  }

  // Keeps a short alias for getting all users.
  Future<List<User>> getUsers() async {
    return getAllUsers();
  }

  // Registers a new user and saves the session locally.
  Future<User> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$host/users/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{}', 408),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final user = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        // Keep the new user logged in after registration.
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userData', jsonEncode(user.toJson()));

        return user;
      } else if (response.statusCode == 408) {
        throw Exception('Request timeout - Check internet');
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Network error - Check internet connection');
    } on http.ClientException catch (e) {
      throw Exception('Connection error: ${e.message}');
    } catch (e) {
      throw Exception('Error registering user: $e');
    }
  }

  // Checks whether a user is currently logged in.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Reads the saved user details.
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString('userData');

    if (rawData == null || rawData.isEmpty) {
      return {};
    }

    return jsonDecode(rawData);
  }

  // Clears the saved login session.
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userData');
      return;
    } catch (e) {
      throw Exception('Error logging out: $e');
    }
  }
}
