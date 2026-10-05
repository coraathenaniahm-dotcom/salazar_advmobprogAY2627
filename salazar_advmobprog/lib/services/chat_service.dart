import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String conversationId(String userId, String otherUserId) {
    final ids = [userId, otherUserId]..sort();
    return ids.join('_');
  }

  Future<void> sendMessage(String receiverId, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not signed in.');
    }

    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return;
    }

    if (currentUser.uid == receiverId) {
      throw Exception('You cannot start a chat with yourself.');
    }

    final timestamp = Timestamp.now();
    final chatRoomId = conversationId(currentUser.uid, receiverId);

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'users': [currentUser.uid, receiverId],
      'lastMessage': trimmedMessage,
      'lastMessageTime': timestamp,
    }, SetOptions(merge: true));

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
          'senderId': currentUser.uid,
          'receiverId': receiverId,
          'message': trimmedMessage,
          'timestamp': timestamp,
          'isRead': false,
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(
    String userId,
    String otherUserId,
  ) {
    final chatRoomId = conversationId(userId, otherUserId);

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('username')
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> markMessagesAsRead(String userId, String otherUserId) async {
    final chatRoomId = conversationId(userId, otherUserId);
    final messages = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final message in messages.docs) {
      await message.reference.update({'isRead': true});
    }
  }
}
