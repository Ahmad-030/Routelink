import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';

/// ============================================
/// CHAT SCREEN
/// Real-time chat between driver and passenger
/// ============================================

class ChatScreen extends StatefulWidget {
  final String userName;
  final bool isDriver;

  const ChatScreen({
    super.key,
    required this.userName,
    this.isDriver = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // Mock messages
  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'text': 'Hi! I saw your ride request.',
      'isMe': false,
      'time': '10:30 AM',
    },
    {
      'id': '2',
      'text': 'Hello! Yes, I need a ride to DHA Phase 5.',
      'isMe': true,
      'time': '10:31 AM',
    },
    {
      'id': '3',
      'text': 'I can pick you up in about 5 minutes. Is that okay?',
      'isMe': false,
      'time': '10:32 AM',
    },
    {
      'id': '4',
      'text': 'Perfect! I\'ll be waiting near the main gate.',
      'isMe': true,
      'time': '10:32 AM',
    },
    {
      'id': '5',
      'text': 'Great! See you soon 👍',
      'isMe': false,
      'time': '10:33 AM',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': _messageController.text.trim(),
        'isMe': true,
        'time': 'Now',
      });
    });

    _messageController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Ride info banner
          _buildRideInfoBanner(isDark),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['isMe'] as bool;

                return _buildMessageBubble(
                  message: message,
                  isMe: isMe,
                  isDark: isDark,
                  index: index,
                );
              },
            ),
          ),

          // Message input
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Iconsax.arrow_left,
          color: isDark ? Colors.white : AppColors.grey900,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.userName.substring(0, 1).toUpperCase(),
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBackground,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName,
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.online,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Online',
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      color: AppColors.online,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Iconsax.call,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(
            Iconsax.more,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildRideInfoBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryYellow.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Iconsax.car,
              color: AppColors.darkBackground,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isDriver ? 'Ride Request' : 'Your Ride',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                Text(
                  'Model Town → DHA Phase 5',
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Rs. 300',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBackground,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildMessageBubble({
    required Map<String, dynamic> message,
    required bool isMe,
    required bool isDark,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.userName.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBackground,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primaryYellow
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? null
                    : Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message['text'],
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isMe
                          ? AppColors.darkBackground
                          : (isDark ? Colors.white : AppColors.grey900),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message['time'],
                        style: GoogleFonts.urbanist(
                          fontSize: 11,
                          color: isMe
                              ? AppColors.darkBackground.withOpacity(0.6)
                              : AppColors.grey500,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Iconsax.tick_circle5,
                          size: 14,
                          color: AppColors.darkBackground.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 8),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 50).ms)
        .slideX(begin: isMe ? 0.1 : -0.1, end: 0);
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachment button
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Iconsax.attach_circle,
                  color: AppColors.grey500,
                ),
                onPressed: () {},
              ),
            ),

            const SizedBox(width: 12),

            // Text input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.grey100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.urbanist(
                      fontSize: 15,
                      color: AppColors.grey500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Iconsax.send_1,
                  color: AppColors.darkBackground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}