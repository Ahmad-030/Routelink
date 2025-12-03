/// ============================================
/// RIDE REQUEST MODEL
/// Represents a ride request from passenger
/// ============================================

class RideRequestModel {
  final String id;
  final String rideId;
  final String passengerId;
  final String passengerName;
  final String? passengerPhoto;
  final double passengerRating;
  final String pickupAddress;
  final String dropoffAddress;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final int offeredFare;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message;
  final double? distance;
  final int? estimatedDuration;

  RideRequestModel({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    this.passengerPhoto,
    this.passengerRating = 5.0,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.offeredFare,
    this.status = RequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.message,
    this.distance,
    this.estimatedDuration,
  });

  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    return RideRequestModel(
      id: json['id'] ?? '',
      rideId: json['rideId'] ?? '',
      passengerId: json['passengerId'] ?? '',
      passengerName: json['passengerName'] ?? '',
      passengerPhoto: json['passengerPhoto'],
      passengerRating: (json['passengerRating'] ?? 5.0).toDouble(),
      pickupAddress: json['pickupAddress'] ?? '',
      dropoffAddress: json['dropoffAddress'] ?? '',
      pickupLat: (json['pickupLat'] ?? 0.0).toDouble(),
      pickupLng: (json['pickupLng'] ?? 0.0).toDouble(),
      dropoffLat: (json['dropoffLat'] ?? 0.0).toDouble(),
      dropoffLng: (json['dropoffLng'] ?? 0.0).toDouble(),
      offeredFare: json['offeredFare'] ?? 0,
      status: RequestStatus.values.firstWhere(
            (e) => e.name == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : null,
      message: json['message'],
      distance: json['distance']?.toDouble(),
      estimatedDuration: json['estimatedDuration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhoto': passengerPhoto,
      'passengerRating': passengerRating,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'offeredFare': offeredFare,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'message': message,
      'distance': distance,
      'estimatedDuration': estimatedDuration,
    };
  }

  RideRequestModel copyWith({
    String? id,
    String? rideId,
    String? passengerId,
    String? passengerName,
    String? passengerPhoto,
    double? passengerRating,
    String? pickupAddress,
    String? dropoffAddress,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    int? offeredFare,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? message,
    double? distance,
    int? estimatedDuration,
  }) {
    return RideRequestModel(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerPhoto: passengerPhoto ?? this.passengerPhoto,
      passengerRating: passengerRating ?? this.passengerRating,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      offeredFare: offeredFare ?? this.offeredFare,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
      distance: distance ?? this.distance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }
}

/// Request Status
enum RequestStatus {
  pending,    // Waiting for driver response
  accepted,   // Driver accepted the request
  rejected,   // Driver rejected the request
  cancelled,  // Passenger cancelled the request
  negotiating, // In negotiation
  expired,    // Request timed out
}