import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../Services/Firebase Auth.dart';
import '../Chat/Chat_Screen.dart';

/// ============================================
/// PASSENGER CHATS SCREEN
/// Shows all chat conversations
/// ============================================

class PassengerChatsScreen extends StatefulWidget {
  const PassengerChatsScreen({super.key});

  @override
  State<PassengerChatsScreen> createState() => _PassengerChatsScreenState();
}

class _PassengerChatsScreenState extends State<PassengerChatsScreen> {
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  StreamSubscription? _chatsSubscription;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    super.dispose();
  }

  void _loadChats() {
    final userId = AuthService.to.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _chatsSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final chats = snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatConversation(
          id: doc.id,
          otherUserId: _getOtherUserId(data['participants'] as List, userId),
          otherUserName: data['driverName'] ?? 'Driver',
          lastMessage: data['lastMessage'] ?? '',
          lastMessageAt: data['lastMessageAt'] != null
              ? (data['lastMessageAt'] as Timestamp).toDate()
              : DateTime.now(),
          unreadCount: data['unreadCount_$userId'] ?? 0,
          isOnline: data['driverOnline'] ?? false,
        );
      }).toList();

      setState(() {
        _conversations = chats;
        _isLoading = false;
      });
    }, onError: (e) {
      debugPrint('Chats stream error: $e');
      setState(() => _isLoading = false);
    });
  }

  String _getOtherUserId(List participants, String currentUserId) {
    return participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Messages',
          style: GoogleFonts.urbanist(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Iconsax.search_normal,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
            onPressed: () {
              // TODO: Search chats
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
        ),
      )
          : _conversations.isEmpty
          ? _buildEmptyState(isDark)
          : RefreshIndicator(
        color: AppColors.primaryYellow,
        onRefresh: () async => _loadChats(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _conversations.length,
          itemBuilder: (context, index) {
            final chat = _conversations[index];
            return _ChatTile(
              chat: chat,
              onTap: () => Get.to(
                    () => ChatScreen(
                  userName: chat.otherUserName,
                  isDriver: false,
                ),
                transition: Transition.rightToLeftWithFade,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms).slideX(begin: 0.1, end: 0);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.message,
              size: 48,
              color: AppColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Messages Yet',
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your driver',
            style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}

class ChatConversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOnline;

  ChatConversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.isOnline,
  });
}

class _ChatTile extends StatelessWidget {
  final ChatConversation chat;
  final VoidCallback onTap;

  const _ChatTile({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = chat.unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasUnread
                ? AppColors.primaryYellow.withOpacity(0.5)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: hasUnread
                        ? AppColors.primaryGradient
                        : null,
                    color: hasUnread ? null : (isDark ? AppColors.darkElevated : AppColors.grey200),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      chat.otherUserName.isNotEmpty
                          ? chat.otherUserName.substring(0, 1).toUpperCase()
                          : 'D',
                      style: GoogleFonts.urbanist(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: hasUnread ? AppColors.darkBackground : AppColors.grey500,
                      ),
                    ),
                  ),
                ),
                if (chat.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat.otherUserName,
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                      Text(
                        _formatTime(chat.lastMessageAt),
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                          color: hasUnread ? AppColors.primaryYellow : AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                            color: hasUnread
                                ? (isDark ? Colors.white70 : AppColors.grey700)
                                : AppColors.grey500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${chat.unreadCount}',
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkBackground,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}