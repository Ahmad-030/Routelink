/// ============================================
/// RIDE MODEL
/// Core model for rides in the app
/// ============================================

enum RideStatus {
  active,    // Driver posted route, waiting for passengers
  accepted,  // Passenger request accepted
  inProgress, // Ride is ongoing
  completed,  // Ride finished
  cancelled,  // Ride was cancelled
}

class RideModel {
  final String id;
  final String driverId;
  final String? driverName;
  final double? driverRating;
  final LocationPoint startLocation;
  final LocationPoint endLocation;
  final CarDetails carDetails;
  final int availableSeats;
  final int? suggestedFare;
  final int? acceptedFare;
  final double? distance;
  final int? estimatedDuration;
  final RideStatus status;
  final String? passengerId;
  final String? passengerName;
  final double? passengerRating;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final List<String>? routePolyline;

  RideModel({
    required this.id,
    required this.driverId,
    this.driverName,
    this.driverRating,
    required this.startLocation,
    required this.endLocation,
    required this.carDetails,
    required this.availableSeats,
    this.suggestedFare,
    this.acceptedFare,
    this.distance,
    this.estimatedDuration,
    required this.status,
    this.passengerId,
    this.passengerName,
    this.passengerRating,
    this.createdAt,
    this.completedAt,
    this.routePolyline,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'],
      driverRating: json['driverRating']?.toDouble(),
      startLocation: LocationPoint.fromJson(json['startLocation'] ?? {}),
      endLocation: LocationPoint.fromJson(json['endLocation'] ?? {}),
      carDetails: CarDetails.fromJson(json['carDetails'] ?? {}),
      availableSeats: json['availableSeats'] ?? 1,
      suggestedFare: json['suggestedFare'],
      acceptedFare: json['acceptedFare'],
      distance: json['distance']?.toDouble(),
      estimatedDuration: json['estimatedDuration'],
      status: _parseStatus(json['status']),
      passengerId: json['passengerId'],
      passengerName: json['passengerName'],
      passengerRating: json['passengerRating']?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      routePolyline: json['routePolyline'] != null
          ? List<String>.from(json['routePolyline'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'driverRating': driverRating,
      'startLocation': startLocation.toJson(),
      'endLocation': endLocation.toJson(),
      'carDetails': carDetails.toJson(),
      'availableSeats': availableSeats,
      'suggestedFare': suggestedFare,
      'acceptedFare': acceptedFare,
      'distance': distance,
      'estimatedDuration': estimatedDuration,
      'status': status.name,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerRating': passengerRating,
      'createdAt': createdAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'routePolyline': routePolyline,
    };
  }

  static RideStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return RideStatus.active;
      case 'accepted':
        return RideStatus.accepted;
      case 'inprogress':
        return RideStatus.inProgress;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.active;
    }
  }

  RideModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    double? driverRating,
    LocationPoint? startLocation,
    LocationPoint? endLocation,
    CarDetails? carDetails,
    int? availableSeats,
    int? suggestedFare,
    int? acceptedFare,
    double? distance,
    int? estimatedDuration,
    RideStatus? status,
    String? passengerId,
    String? passengerName,
    double? passengerRating,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? routePolyline,
  }) {
    return RideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverRating: driverRating ?? this.driverRating,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      carDetails: carDetails ?? this.carDetails,
      availableSeats: availableSeats ?? this.availableSeats,
      suggestedFare: suggestedFare ?? this.suggestedFare,
      acceptedFare: acceptedFare ?? this.acceptedFare,
      distance: distance ?? this.distance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      status: status ?? this.status,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerRating: passengerRating ?? this.passengerRating,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      routePolyline: routePolyline ?? this.routePolyline,
    );
  }
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final String address;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
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

class CarDetails {
  final String name;
  final String number;
  final String? color;
  final String? type;

  CarDetails({
    required this.name,
    required this.number,
    this.color,
    this.type,
  });

  factory CarDetails.fromJson(Map<String, dynamic> json) {
    return CarDetails(
      name: json['name'] ?? '',
      number: json['number'] ?? '',
      color: json['color'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'number': number,
      'color': color,
      'type': type,
    };
  }
}