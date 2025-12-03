/// ============================================
/// USER MODEL
/// Represents a user (driver or passenger)
/// ============================================

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final UserRole role;
  final double rating;
  final int totalRides;
  final DateTime createdAt;
  final bool isVerified;
  final bool isOnline;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.role,
    this.rating = 5.0,
    this.totalRides = 0,
    required this.createdAt,
    this.isVerified = false,
    this.isOnline = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      photoUrl: json['photoUrl'],
      role: UserRole.values.firstWhere(
            (e) => e.name == json['role'],
        orElse: () => UserRole.passenger,
      ),
      rating: (json['rating'] ?? 5.0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isVerified: json['isVerified'] ?? false,
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role.name,
      'rating': rating,
      'totalRides': totalRides,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
      'isOnline': isOnline,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    UserRole? role,
    double? rating,
    int? totalRides,
    DateTime? createdAt,
    bool? isVerified,
    bool? isOnline,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

enum UserRole {
  driver,
  passenger,
}