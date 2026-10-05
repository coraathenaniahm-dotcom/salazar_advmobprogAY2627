import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_details_screen.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final currentUser = _auth.currentUser;
      final users = await _chatService.getUsers();
      final filteredUsers = users.where((user) {
        final userId = (user['id'] ?? '').toString();
        return currentUser == null || userId != currentUser.uid;
      }).toList();

      if (!mounted) return;
      setState(() {
        _users = filteredUsers;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load users: $error')));
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _users;
    }

    return _users.where((user) {
      final email = (user['email'] ?? '').toString().toLowerCase();
      final username = (user['username'] ?? '').toString().toLowerCase();
      return email.contains(query) || username.contains(query);
    }).toList();
  }

  void _openChat(Map<String, dynamic> user) {
    final currentUser = _auth.currentUser;
    final selectedUserId = (user['id'] ?? '').toString();

    if (currentUser != null && currentUser.uid == selectedUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot chat with yourself.')),
      );
      return;
    }

    final email = (user['email'] ?? '').toString();
    final username = (user['username'] ?? '').toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailsScreen(
          receiverUserId: selectedUserId,
          receiverEmail: email,
          receiverName: username.isNotEmpty ? username : email,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in to chat')));
    }

    final filteredUsers = _filteredUsers;

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredUsers.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.separated(
                          itemCount: filteredUsers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final email = (user['email'] ?? 'Unknown')
                                .toString();
                            final username = (user['username'] ?? '')
                                .toString();
                            final title = username.isNotEmpty
                                ? username
                                : email;
                            final initials = title.isNotEmpty
                                ? title[0].toUpperCase()
                                : 'U';

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(
                                  0xFF394B9D,
                                ).withOpacity(0.18),
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Color(0xFF394B9D),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(title),
                              subtitle: Text(email),
                              trailing: const Icon(Icons.chat_bubble_outline),
                              onTap: () => _openChat(user),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
