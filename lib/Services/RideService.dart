import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:routelink/Services/Firebase%20Auth.dart';
import '../Models/Ride_model.dart';
import '../Models/Ride_request_model.dart';

/// ============================================
/// RIDE SERVICE
/// Handles ride creation, requests, and real-time updates
/// ============================================

class RideService extends GetxController {
  static RideService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  final RxList<RideModel> _activeRides = <RideModel>[].obs;
  final RxList<RideRequestModel> _rideRequests = <RideRequestModel>[].obs;
  final Rx<RideModel?> _currentRide = Rx<RideModel?>(null);

  List<RideModel> get activeRides => _activeRides;
  List<RideRequestModel> get rideRequests => _rideRequests;
  RideModel? get currentRide => _currentRide.value;

  @override
  void onInit() {
    super.onInit();
    _listenToActiveRides();
    _listenToRideRequests();
  }

  // Listen to active rides
  void _listenToActiveRides() {
    _firestore
        .collection('rides')
        .where('status', whereIn: ['active', 'inProgress'])
        .snapshots()
        .listen((snapshot) {
      _activeRides.value = snapshot.docs
          .map((doc) => RideModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  // Listen to ride requests for current user
  void _listenToRideRequests() {
    final userId = AuthService.to.currentUser?.id;
    if (userId == null) return;

    _firestore
        .collection('ride_requests')
        .where('rideId', isEqualTo: _currentRide.value?.id)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      _rideRequests.value = snapshot.docs
          .map((doc) => RideRequestModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  // Create a new ride (for drivers)
  Future<String?> createRide({
    required LocationPoint startLocation,
    required LocationPoint endLocation,
    required CarDetails carDetails,
    required int availableSeats,
    int? suggestedFare,
    List<LocationPoint>? viaPoints,
  }) async {
    try {
      final user = AuthService.to.currentUser;
      if (user == null) return null;

      final ride = RideModel(
        id: '',
        driverId: user.id,
        driverName: user.name,
        startLocation: startLocation,
        endLocation: endLocation,
        viaPoints: viaPoints ?? [],
        carDetails: carDetails,
        availableSeats: availableSeats,
        suggestedFare: suggestedFare,
        status: RideStatus.active,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('rides').add(ride.toJson());
      _currentRide.value = ride.copyWith(id: docRef.id);

      // Update real-time location
      await _database.ref('ride_locations/${docRef.id}').set({
        'driverId': user.id,
        'latitude': startLocation.latitude,
        'longitude': startLocation.longitude,
        'timestamp': ServerValue.timestamp,
      });

      return docRef.id;
    } catch (e) {
      Get.snackbar('Error', 'Failed to create ride: $e');
      return null;
    }
  }

  // Send ride request (for passengers)
  Future<bool> sendRideRequest({
    required String rideId,
    required String pickupAddress,
    required String dropoffAddress,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required int offeredFare,
    String? message,
  }) async {
    try {
      final user = AuthService.to.currentUser;
      if (user == null) return false;

      final request = RideRequestModel(
        id: '',
        rideId: rideId,
        passengerId: user.id,
        passengerName: user.name,
        passengerRating: user.rating,
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        offeredFare: offeredFare,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
        message: message,
      );

      await _firestore.collection('ride_requests').add(request.toJson());
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to send request: $e');
      return false;
    }
  }

  // Accept ride request (for drivers)
  Future<bool> acceptRideRequest(String requestId) async {
    try {
      await _firestore.collection('ride_requests').doc(requestId).update({
        'status': RequestStatus.accepted.name,
        'respondedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept request: $e');
      return false;
    }
  }

  // Reject ride request (for drivers)
  Future<bool> rejectRideRequest(String requestId) async {
    try {
      await _firestore.collection('ride_requests').doc(requestId).update({
        'status': RequestStatus.rejected.name,
        'respondedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject request: $e');
      return false;
    }
  }

  // Update ride location (real-time)
  Future<void> updateRideLocation(double lat, double lng) async {
    if (_currentRide.value == null) return;

    try {
      await _database.ref('ride_locations/${_currentRide.value!.id}').update({
        'latitude': lat,
        'longitude': lng,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  // Start ride
  Future<bool> startRide(String rideId) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': RideStatus.inProgress.name,
        'startedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to start ride: $e');
      return false;
    }
  }

  // Complete ride
  Future<bool> completeRide(String rideId) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': RideStatus.completed.name,
        'completedAt': DateTime.now().toIso8601String(),
      });

      _currentRide.value = null;
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to complete ride: $e');
      return false;
    }
  }

  // Cancel ride
  Future<bool> cancelRide(String rideId) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': RideStatus.cancelled.name,
      });

      // Remove real-time location
      await _database.ref('ride_locations/$rideId').remove();

      _currentRide.value = null;
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel ride: $e');
      return false;
    }
  }

  // Get nearby rides for passenger
  Stream<List<RideModel>> getNearbyRides(double lat, double lng, double radiusKm) {
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: RideStatus.active.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RideModel.fromJson({'id': doc.id, ...doc.data()}))
          .where((ride) {
        // Calculate distance (simplified)
        final distance = _calculateDistance(
          lat,
          lng,
          ride.startLocation.latitude,
          ride.startLocation.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    });
  }

  // Simple distance calculation (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = 0.5 -
        (0.5 * (1 - (2 * 0.5 * dLat * dLat))) +
        (0.5 * (1 + (2 * 0.5 * lat1 * lat1))) *
            (0.5 * (1 + (2 * 0.5 * lat2 * lat2))) *
            (0.5 - (0.5 * (1 - (2 * 0.5 * dLon * dLon))));
    return R * 2 * 3.14159 * a;
  }

  double _toRadians(double degrees) {
    return degrees * 3.14159 / 180;
  }
}