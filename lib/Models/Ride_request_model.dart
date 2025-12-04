/// ============================================
/// RIDE REQUEST MODEL
/// Model for ride requests from passengers
/// ============================================

class RideRequestModel {
  final String id;
  final String rideId;
  final String driverId;
  final String passengerId;
  final String passengerName;
  final double passengerRating;
  final String pickupAddress;
  final String dropoffAddress;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final int offeredFare;
  final int? suggestedFare;
  final double? distance;
  final String status; // pending, accepted, rejected, cancelled
  final DateTime? createdAt;

  RideRequestModel({
    required this.id,
    required this.rideId,
    required this.driverId,
    required this.passengerId,
    required this.passengerName,
    required this.passengerRating,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.offeredFare,
    this.suggestedFare,
    this.distance,
    required this.status,
    this.createdAt,
  });

  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    return RideRequestModel(
      id: json['id'] ?? '',
      rideId: json['rideId'] ?? '',
      driverId: json['driverId'] ?? '',
      passengerId: json['passengerId'] ?? '',
      passengerName: json['passengerName'] ?? 'Passenger',
      passengerRating: (json['passengerRating'] ?? 5.0).toDouble(),
      pickupAddress: json['pickupAddress'] ?? '',
      dropoffAddress: json['dropoffAddress'] ?? '',
      pickupLat: (json['pickupLat'] ?? 0.0).toDouble(),
      pickupLng: (json['pickupLng'] ?? 0.0).toDouble(),
      dropoffLat: (json['dropoffLat'] ?? 0.0).toDouble(),
      dropoffLng: (json['dropoffLng'] ?? 0.0).toDouble(),
      offeredFare: json['offeredFare'] ?? 0,
      suggestedFare: json['suggestedFare'],
      distance: json['distance']?.toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'driverId': driverId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerRating': passengerRating,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'offeredFare': offeredFare,
      'suggestedFare': suggestedFare,
      'distance': distance,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  RideRequestModel copyWith({
    String? id,
    String? rideId,
    String? driverId,
    String? passengerId,
    String? passengerName,
    double? passengerRating,
    String? pickupAddress,
    String? dropoffAddress,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    int? offeredFare,
    int? suggestedFare,
    double? distance,
    String? status,
    DateTime? createdAt,
  }) {
    return RideRequestModel(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerRating: passengerRating ?? this.passengerRating,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      offeredFare: offeredFare ?? this.offeredFare,
      suggestedFare: suggestedFare ?? this.suggestedFare,
      distance: distance ?? this.distance,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}