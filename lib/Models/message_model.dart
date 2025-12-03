/// ============================================
/// MESSAGE MODEL
/// Represents a chat message
/// ============================================

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final LocationData? location;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.location,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      text: json['text'] ?? '',
      type: MessageType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
      location: json['location'] != null
          ? LocationData.fromJson(json['location'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'location': location?.toJson(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? text,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    LocationData? location,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
    );
  }
}

/// Message Type
enum MessageType {
  text,
  image,
  location,
  fareOffer,
  rideAccepted,
  rideRejected,
  system,
}

/// Location Data for sharing location in chat
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}

/// Chat Model - Represents a conversation
class ChatModel {
  final String id;
  final String rideId;
  final List<String> participants;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.rideId,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? '',
      rideId: json['rideId'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'participants': participants,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}