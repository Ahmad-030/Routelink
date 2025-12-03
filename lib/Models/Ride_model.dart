/// ============================================
/// RIDE MODEL
/// Represents a ride/route
/// ============================================

class RideModel {
  final String id;
  final String driverId;
  final String driverName;
  final String? passengerId;
  final String? passengerName;
  final LocationPoint startLocation;
  final LocationPoint endLocation;
  final List<LocationPoint> viaPoints;
  final CarDetails carDetails;
  final int availableSeats;
  final int? suggestedFare;
  final int? offeredFare;
  final int? acceptedFare;
  final RideStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? polyline;
  final double? distance;
  final int? estimatedDuration;

  RideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.passengerId,
    this.passengerName,
    required this.startLocation,
    required this.endLocation,
    this.viaPoints = const [],
    required this.carDetails,
    required this.availableSeats,
    this.suggestedFare,
    this.offeredFare,
    this.acceptedFare,
    this.status = RideStatus.active,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.polyline,
    this.distance,
    this.estimatedDuration,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'] ?? '',
      passengerId: json['passengerId'],
      passengerName: json['passengerName'],
      startLocation: LocationPoint.fromJson(json['startLocation'] ?? {}),
      endLocation: LocationPoint.fromJson(json['endLocation'] ?? {}),
      viaPoints: (json['viaPoints'] as List<dynamic>?)
          ?.map((e) => LocationPoint.fromJson(e))
          .toList() ??
          [],
      carDetails: CarDetails.fromJson(json['carDetails'] ?? {}),
      availableSeats: json['availableSeats'] ?? 1,
      suggestedFare: json['suggestedFare'],
      offeredFare: json['offeredFare'],
      acceptedFare: json['acceptedFare'],
      status: RideStatus.values.firstWhere(
            (e) => e.name == json['status'],
        orElse: () => RideStatus.active,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      polyline: json['polyline'],
      distance: json['distance']?.toDouble(),
      estimatedDuration: json['estimatedDuration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'startLocation': startLocation.toJson(),
      'endLocation': endLocation.toJson(),
      'viaPoints': viaPoints.map((e) => e.toJson()).toList(),
      'carDetails': carDetails.toJson(),
      'availableSeats': availableSeats,
      'suggestedFare': suggestedFare,
      'offeredFare': offeredFare,
      'acceptedFare': acceptedFare,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'polyline': polyline,
      'distance': distance,
      'estimatedDuration': estimatedDuration,
    };
  }

  RideModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? passengerId,
    String? passengerName,
    LocationPoint? startLocation,
    LocationPoint? endLocation,
    List<LocationPoint>? viaPoints,
    CarDetails? carDetails,
    int? availableSeats,
    int? suggestedFare,
    int? offeredFare,
    int? acceptedFare,
    RideStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? polyline,
    double? distance,
    int? estimatedDuration,
  }) {
    return RideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      viaPoints: viaPoints ?? this.viaPoints,
      carDetails: carDetails ?? this.carDetails,
      availableSeats: availableSeats ?? this.availableSeats,
      suggestedFare: suggestedFare ?? this.suggestedFare,
      offeredFare: offeredFare ?? this.offeredFare,
      acceptedFare: acceptedFare ?? this.acceptedFare,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      polyline: polyline ?? this.polyline,
      distance: distance ?? this.distance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }
}

/// Location Point
class LocationPoint {
  final double latitude;
  final double longitude;
  final String address;
  final String? name;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.name,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'name': name,
    };
  }
}

/// Car Details
class CarDetails {
  final String name;
  final String number;
  final String? color;
  final String? model;

  CarDetails({
    required this.name,
    required this.number,
    this.color,
    this.model,
  });

  factory CarDetails.fromJson(Map<String, dynamic> json) {
    return CarDetails(
      name: json['name'] ?? '',
      number: json['number'] ?? '',
      color: json['color'],
      model: json['model'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'number': number,
      'color': color,
      'model': model,
    };
  }
}

/// Ride Status
enum RideStatus {
  active,      // Route is published, waiting for passengers
  requested,   // Passenger has requested
  accepted,    // Driver accepted the request
  inProgress,  // Ride is ongoing
  completed,   // Ride completed
  cancelled,   // Ride was cancelled
}