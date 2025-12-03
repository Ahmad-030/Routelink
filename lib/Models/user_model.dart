// Make sure your UserModel has proper role conversion
// This should be in your user_model.dart file

import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  driver,
  passenger,
}

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

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last, // Saves as 'driver' or 'passenger'
      'profileImage': profileImage,
      'rating': rating,
      'totalRides': totalRides,
      'createdAt': Timestamp.fromDate(createdAt), // Save as Firestore Timestamp
    };
  }

  // Create UserModel from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Handle createdAt field - can be either Timestamp or String
    DateTime createdAtDate;
    if (map['createdAt'] is Timestamp) {
      // If it's a Firestore Timestamp, convert to DateTime
      createdAtDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      // If it's a String, parse it
      createdAtDate = DateTime.parse(map['createdAt']);
    } else {
      // Fallback to current time
      createdAtDate = DateTime.now();
    }

    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      // CRITICAL: Properly convert string to enum
      role: map['role'] == 'driver' ? UserRole.driver : UserRole.passenger,
      profileImage: map['profileImage'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalRides: map['totalRides'] ?? 0,
      createdAt: createdAtDate,
    );
  }

  // Create a copy with some fields changed
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
}