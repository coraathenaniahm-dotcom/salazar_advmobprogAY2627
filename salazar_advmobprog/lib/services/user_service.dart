import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  static const String dummyJsonLoginType = 'dummyjson';
  static const String firebaseLoginType = 'firebase';

  static User userFromFirebaseProfile({
    required String uid,
    required String email,
    String? displayName,
    Map<String, dynamic>? profileData,
  }) {
    final profile = profileData ?? const {};
    final username =
        (profile['username'] ?? displayName ?? email.split('@').first)
            .toString()
            .trim();

    return User(
      id: uid.hashCode.abs() % 1000000007,
      firstName: (profile['firstName'] ?? '').toString(),
      lastName: (profile['lastName'] ?? '').toString(),
      username: username,
      email: email,
      image: (profile['image'] ?? '').toString(),
    );
  }

  final firebase_auth.FirebaseAuth firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  Stream<firebase_auth.User?> get authStateChanges =>
      firebaseAuth.authStateChanges();

  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'no-user',
        message: 'No user was returned from Firebase.',
      );
    }

    final profileDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    final user = userFromFirebaseProfile(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? email,
      displayName: firebaseUser.displayName,
      profileData: profileDoc.data(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('loginType', firebaseLoginType);
    await prefs.setString('userData', jsonEncode(user.toJson()));
    return credential;
  }

  Future<firebase_auth.UserCredential> createAccount({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
  }) async {
    final credential = await _createOrResumeFirebaseAccount(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'no-user',
        message: 'No user was created in Firebase.',
      );
    }

    final resolvedUsername =
        (username ?? firebaseUser.displayName ?? email.split('@').first).trim();
    final profileData = {
      'uid': firebaseUser.uid,
      'firstName': firstName ?? '',
      'lastName': lastName ?? '',
      'username': resolvedUsername,
      'email': email,
      'image': '',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await firebaseUser.updateDisplayName(resolvedUsername);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .set(profileData, SetOptions(merge: true));

    final user = userFromFirebaseProfile(
      uid: firebaseUser.uid,
      email: email,
      displayName: resolvedUsername,
      profileData: profileData,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('loginType', firebaseLoginType);
    await prefs.setString('userData', jsonEncode(user.toJson()));
    return credential;
  }

  Future<firebase_auth.UserCredential> _createOrResumeFirebaseAccount({
    required String email,
    required String password,
  }) async {
    Future<firebase_auth.UserCredential> create() {
      return firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }

    Future<firebase_auth.UserCredential> resumeExistingAccount() {
      return firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }

    try {
      return await create();
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        return resumeExistingAccount();
      }

      final message = '${error.code} ${error.message}'.toLowerCase();
      final isTransientNetworkError =
          message.contains('connection reset') ||
          message.contains('network request failed') ||
          message.contains('timed out');
      if (!isTransientNetworkError) rethrow;

      await Future<void>.delayed(const Duration(seconds: 1));
      try {
        return await create();
      } on firebase_auth.FirebaseAuthException catch (retryError) {
        if (retryError.code == 'email-already-in-use') {
          return resumeExistingAccount();
        }
        rethrow;
      }
    }
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    if (await getLoginType() == firebaseLoginType) {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user is currently signed in.',
        );
      }
      await currentUser.updateDisplayName(username);

      final userData = await getUserData();
      if (userData.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'userData',
          jsonEncode({...userData, 'username': username}),
        );
      }
      return;
    }

    final userData = await getUserData();
    final userId = userData['id'];
    if (userId == null) throw Exception('No saved user session');

    // DummyJSON users created through /users/add are not reliably updateable.
    await _saveUserData({...userData, 'username': username});
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    if (await getLoginType() != firebaseLoginType) {
      final userData = await getUserData();
      final userId = userData['id'];
      if (userId == null) throw Exception('No saved user session');

      final response = await http.delete(Uri.parse('$host/users/$userId'));
      if (response.statusCode != 200 && response.statusCode != 404) {
        throw Exception('Failed to delete account: ${response.statusCode}');
      }
      // A 404 means the simulated DummyJSON user is already absent remotely.
      await logout();
      return;
    }

    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }

    await currentUser.reauthenticateWithCredential(credential);
    await currentUser.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    if (await getLoginType() != firebaseLoginType) {
      final userData = await getUserData();
      final userId = userData['id'];
      if (userId == null) throw Exception('No saved user session');

      final updatedUser = await _updateDummyJsonUser(userId, {
        'password': newPassword,
      });
      await _saveUserData(updatedUser);
      return;
    }

    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }

    await currentUser.reauthenticateWithCredential(credential);
    await currentUser.updatePassword(newPassword);
  }

  // Emails use Firebase; usernames use the DummyJSON demo account endpoint.
  Future<User> login(String identifier, String password) async {
    if (identifier.contains('@')) {
      await signIn(email: identifier, password: password);
      return User.fromJson(await getUserData());
    }

    final response = await http
        .post(
          Uri.parse('$host/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': identifier,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      final message = errorData is Map<String, dynamic>
          ? errorData['message']?.toString()
          : null;
      throw Exception(
        message ?? 'DummyJSON login failed: ${response.statusCode}',
      );
    }

    final user = User.fromJson(jsonDecode(response.body));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userData', jsonEncode(user.toJson()));
    await prefs.setString('loginType', dummyJsonLoginType);
    return user;
  }

  // Fetch one user by ID.
  Future<User> getUserById(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$host/users/$userId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
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

  // Fetch all users.
  Future<List<User>> getAllUsers() async {
    try {
      final response = await http
          .get(
            Uri.parse('$host/users'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
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

  // Alias for fetching users.
  Future<List<User>> getUsers() async {
    return getAllUsers();
  }

  // Register a user and save the session.
  Future<User> register(Map<String, dynamic> userData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$host/users/add'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(userData),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => http.Response('{}', 408),
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final user = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        // Save the newly registered user locally.
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userData', jsonEncode(user.toJson()));
        await prefs.setString('loginType', dummyJsonLoginType);

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

  // Check whether a session exists.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Read the saved user data.
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString('userData');

    if (rawData == null || rawData.isEmpty) {
      return {};
    }

    return jsonDecode(rawData);
  }

  Future<String> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginType') ?? dummyJsonLoginType;
  }

  Future<Map<String, dynamic>> _updateDummyJsonUser(
    dynamic userId,
    Map<String, dynamic> changes,
  ) async {
    final response = await http.put(
      Uri.parse('$host/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(changes),
    );

    if (response.statusCode == 404) {
      // DummyJSON does not persist users created through /users/add.
      return {...await getUserData(), ...changes};
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to update user: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final currentData = await getUserData();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString(
      'userData',
      jsonEncode({...currentData, ...userData}),
    );
  }

  // Clear the saved session.
  Future<void> logout() async {
    try {
      await signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userData');
      await prefs.remove('loginType');
      return;
    } catch (e) {
      throw Exception('Error logging out: $e');
    }
  }
}
