import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { driver, passenger }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String profileImage;
  final double rating;
  final int totalRides;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.profileImage,
    required this.rating,
    required this.totalRides,
    required this.createdAt,
  });

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last, // Convert enum to string
      'profileImage': profileImage,
      'rating': rating,
      'totalRides': totalRides,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create UserModel from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: _roleFromString(map['role'] ?? 'passenger'),
      profileImage: map['profileImage'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalRides: map['totalRides'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create UserModel from Firestore DocumentSnapshot
  factory UserModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  /// Helper method to convert string to UserRole enum
  static UserRole _roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return UserRole.driver;
      case 'passenger':
        return UserRole.passenger;
      default:
        return UserRole.passenger;
    }
  }

  /// Copy method for creating modified copies
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? profileImage,
    double? rating,
    int? totalRides,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON string
  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, role: ${role.toString().split('.').last})';
  }

  /// Check if user is a driver
  bool get isDriver => role == UserRole.driver;

  /// Check if user is a passenger
  bool get isPassenger => role == UserRole.passenger;
}