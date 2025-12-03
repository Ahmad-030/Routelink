import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:routelink/Services/Firebase%20Auth.dart';
import '../Models/message_model.dart';

/// ============================================
/// CHAT SERVICE
/// Handles real-time messaging between users
/// ============================================

class ChatService extends GetxController {
  static ChatService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or get chat
  Future<String?> createOrGetChat(String rideId, String otherUserId) async {
    try {
      final currentUserId = AuthService.to.currentUser?.id;
      if (currentUserId == null) return null;

      final participants = [currentUserId, otherUserId]..sort();
      final chatId = '${rideId}_${participants.join('_')}';

      // Check if chat exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // Create new chat
        final chat = ChatModel(
          id: chatId,
          rideId: rideId,
          participants: participants,
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('chats').doc(chatId).set(chat.toJson());
      }

      return chatId;
    } catch (e) {
      Get.snackbar('Error', 'Failed to create chat: $e');
      return null;
    }
  }

  // Send message
  Future<bool> sendMessage({
    required String chatId,
    required String text,
    MessageType type = MessageType.text,
    String? imageUrl,
    LocationData? location,
  }) async {
    try {
      final user = AuthService.to.currentUser;
      if (user == null) return false;

      final message = MessageModel(
        id: '',
        chatId: chatId,
        senderId: user.id,
        senderName: user.name,
        text: text,
        type: type,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        location: location,
      );

      final docRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toJson());

      // Update chat's last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message.toJson(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message: $e');
      return false;
    }
  }

  // Get messages stream
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  // Get user's chats
  Stream<List<ChatModel>> getUserChats() {
    final userId = AuthService.to.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  // Mark messages as read
  Future<void> markAsRead(String chatId) async {
    try {
      final userId = AuthService.to.currentUser?.id;
      if (userId == null) return;

      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messages.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread count
  Stream<int> getUnreadCount(String chatId) {
    final userId = AuthService.to.currentUser?.id;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}