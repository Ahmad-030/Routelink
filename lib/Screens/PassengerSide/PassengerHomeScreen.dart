import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:routelink/Screens/PassengerSide/PassengerChatScreen.dart';
import 'package:routelink/Screens/PassengerSide/PassengerMyRequest.dart';
import 'package:routelink/Screens/PassengerSide/PassengerSettingScreen.dart';
import '../../Core/Theme/App_theme.dart';
import '../../Models/Ride_model.dart';
import '../../Models/Ride_request_model.dart';
import '../../Services/Firebase Auth.dart';
import '../Chat/Chat_Screen.dart';
import 'OfferFare.dart';
import 'PassengerBottomNav.dart';
import 'PassengerHistoryScreen.dart';
import 'PassengerActiveRide.dart';

/// ============================================
/// PASSENGER HOME SCREEN
/// Main screen with Google Maps showing drivers
/// ============================================

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _PassengerHomeContent(),
          PassengerMyRequestsScreen(),
          PassengerChatsScreen(),
          PassengerHistoryScreen(),
          PassengerSettingsScreen(),
        ],
      ),
      bottomNavigationBar: PassengerBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _PassengerHomeContent extends StatefulWidget {
  const _PassengerHomeContent();

  @override
  State<_PassengerHomeContent> createState() => _PassengerHomeContentState();
}

class _PassengerHomeContentState extends State<_PassengerHomeContent> {
  // Google Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Location
  Position? _currentPosition;
  String _currentCity = 'Detecting...';
  bool _isLoadingLocation = true;

  // Rides data
  List<RideModel> _availableRides = [];
  bool _isLoadingRides = true;
  StreamSubscription? _ridesSubscription;

  // Active request/ride
  RideRequestModel? _activeRequest;
  RideModel? _acceptedRide;

  // Search
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Selected ride for highlighting
  RideModel? _selectedRide;

  // API Key - Replace with your key
  static const String _googleMapsApiKey = 'AIzaSyBf_uxaitv3XvVHTSPZHGa20C6q6U8IkkE';

  // Dark map style
  String? _darkMapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _getCurrentLocation();
    _listenToAvailableRides();
    _checkActiveRequest();
  }

  @override
  void dispose() {
    _ridesSubscription?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _loadMapStyle() {
    _darkMapStyle = '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
      {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
      {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#757575"}]},
      {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#181818"}]},
      {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c2c"}]},
      {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8a8a8a"}]},
      {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#373737"}]},
      {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3c3c3c"}]},
      {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
      {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]},
      {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#3d3d3d"}]}
    ]
    ''';
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        setState(() {
          _currentPosition = position;
          _currentCity = _detectCity(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14,
          ),
        );
      } else {
        setState(() {
          _currentCity = 'Location Denied';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Location error: $e');
      setState(() {
        _currentCity = 'Unknown';
        _isLoadingLocation = false;
      });
    }
  }

  String _detectCity(double lat, double lng) {
    if (lat >= 31.3 && lat <= 31.6 && lng >= 73.0 && lng <= 73.3) return 'Faisalabad';
    if (lat >= 31.4 && lat <= 31.7 && lng >= 74.2 && lng <= 74.5) return 'Lahore';
    if (lat >= 33.5 && lat <= 33.8 && lng >= 72.8 && lng <= 73.3) return 'Islamabad';
    if (lat >= 24.8 && lat <= 25.0 && lng >= 66.9 && lng <= 67.2) return 'Karachi';
    return 'Pakistan';
  }

  void _listenToAvailableRides() {
    _ridesSubscription = FirebaseFirestore.instance
        .collection('rides')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final rides = snapshot.docs.map((doc) {
        return RideModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();

      setState(() {
        _availableRides = rides;
        _isLoadingRides = false;
      });

      _updateMapMarkers();
    }, onError: (e) {
      debugPrint('Rides stream error: $e');
      setState(() => _isLoadingRides = false);
    });
  }

  void _checkActiveRequest() {
    final userId = AuthService.to.currentUser?.uid;
    if (userId == null) return;

    // Check for pending requests
    FirebaseFirestore.instance
        .collection('ride_requests')
        .where('passengerId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _activeRequest = RideRequestModel.fromJson({
            'id': snapshot.docs.first.id,
            ...snapshot.docs.first.data(),
          });
        });
      } else {
        setState(() => _activeRequest = null);
      }
    });

    // Check for accepted rides
    FirebaseFirestore.instance
        .collection('rides')
        .where('passengerId', isEqualTo: userId)
        .where('status', whereIn: ['accepted', 'inProgress'])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _acceptedRide = RideModel.fromJson({
            'id': snapshot.docs.first.id,
            ...snapshot.docs.first.data(),
          });
        });
      } else {
        setState(() => _acceptedRide = null);
      }
    });
  }

  void _updateMapMarkers() async {
    _markers.clear();
    _polylines.clear();

    // Current location marker
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );
    }

    // Driver markers and routes
    for (int i = 0; i < _availableRides.length; i++) {
      final ride = _availableRides[i];
      final isSelected = _selectedRide?.id == ride.id;

      // Driver start marker
      _markers.add(
        Marker(
          markerId: MarkerId('driver_${ride.id}'),
          position: LatLng(ride.startLocation.latitude, ride.startLocation.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: ride.driverName ?? 'Driver',
            snippet: 'Rs.${ride.suggestedFare ?? 0} • ${ride.availableSeats} seats',
          ),
          onTap: () => _onDriverMarkerTap(ride),
        ),
      );

      // Destination marker
      _markers.add(
        Marker(
          markerId: MarkerId('destination_${ride.id}'),
          position: LatLng(ride.endLocation.latitude, ride.endLocation.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Drop-off',
            snippet: ride.endLocation.address,
          ),
        ),
      );

      // Route polyline
      if (isSelected) {
        await _getRouteForRide(ride);
      } else {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route_${ride.id}'),
            points: [
              LatLng(ride.startLocation.latitude, ride.startLocation.longitude),
              LatLng(ride.endLocation.latitude, ride.endLocation.longitude),
            ],
            color: Colors.grey.withValues(alpha: 0.5),
            width: 3,
            patterns: [PatternItem.dash(10), PatternItem.gap(10)],
          ),
        );
      }
    }

    setState(() {});
  }

  Future<void> _getRouteForRide(RideModel ride) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${ride.startLocation.latitude},${ride.startLocation.longitude}'
            '&destination=${ride.endLocation.latitude},${ride.endLocation.longitude}'
            '&mode=driving'
            '&key=$_googleMapsApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final polylinePoints = data['routes'][0]['overview_polyline']['points'];
          final routePoints = _decodePolyline(polylinePoints);

          _polylines.add(
            Polyline(
              polylineId: PolylineId('route_${ride.id}'),
              points: routePoints,
              color: AppColors.primaryYellow,
              width: 5,
              patterns: const [],
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );

          _fitBoundsForRoute(routePoints);
        }
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _fitBoundsForRoute(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  void _onDriverMarkerTap(RideModel ride) {
    setState(() => _selectedRide = ride);
    _updateMapMarkers();
    _showOfferFareSheet(ride);
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
    }
  }

  List<RideModel> get _filteredRides {
    if (_searchQuery.isEmpty) return _availableRides;

    return _availableRides.where((ride) {
      final start = ride.startLocation.address.toLowerCase();
      final end = ride.endLocation.address.toLowerCase();
      final driver = (ride.driverName ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return start.contains(query) || end.contains(query) || driver.contains(query);
    }).toList();
  }

  void _showOfferFareSheet(RideModel ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfferFareSheet(
        ride: ride,
        currentPosition: _currentPosition,
        onSubmit: (fare, pickupAddress, dropoffAddress) {
          Navigator.pop(context);
          _sendRideRequest(ride, fare, pickupAddress, dropoffAddress);
        },
      ),
    );
  }

  Future<void> _sendRideRequest(
      RideModel ride,
      int offeredFare,
      String pickupAddress,
      String dropoffAddress,
      ) async {
    final userId = AuthService.to.currentUser?.uid;
    final userName = AuthService.to.currentUser?.name;
    final userRating = AuthService.to.currentUser?.rating ?? 5.0;

    if (userId == null) {
      Get.snackbar('Error', 'Please login to send requests',
          backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }

    try {
      final existingRequest = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('rideId', isEqualTo: ride.id)
          .where('passengerId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        Get.snackbar('Already Requested', 'You have already sent a request for this ride',
            backgroundColor: AppColors.info, colorText: Colors.white);
        return;
      }

      final requestData = {
        'rideId': ride.id,
        'driverId': ride.driverId,
        'passengerId': userId,
        'passengerName': userName ?? 'Passenger',
        'passengerRating': userRating,
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'pickupLat': _currentPosition?.latitude ?? ride.startLocation.latitude,
        'pickupLng': _currentPosition?.longitude ?? ride.startLocation.longitude,
        'dropoffLat': ride.endLocation.latitude,
        'dropoffLng': ride.endLocation.longitude,
        'offeredFare': offeredFare,
        'suggestedFare': ride.suggestedFare,
        'distance': ride.distance,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance.collection('ride_requests').add(requestData);

      Get.snackbar(
        'Request Sent! 🚗',
        'Your offer of Rs. $offeredFare has been sent to ${ride.driverName}',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to send request: $e',
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('ride_requests').doc(requestId).update({
        'status': 'cancelled',
      });
      Get.snackbar('Cancelled', 'Your request has been cancelled',
          backgroundColor: AppColors.grey700, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel request',
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          _buildGoogleMap(isDark),
          _buildTopBar(isDark),
          _buildSearchBar(isDark),
          if (_acceptedRide != null) _buildActiveRideBanner(isDark),
          if (_acceptedRide == null && _activeRequest != null) _buildPendingRequestBanner(isDark),
          _buildMapControls(isDark),
          _buildDriverPanel(isDark),
        ],
      ),
    );
  }

  Widget _buildGoogleMap(bool isDark) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(31.4504, 73.1350),
        zoom: 13,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        if (isDark && _darkMapStyle != null) {
          _mapController!.setMapStyle(_darkMapStyle);
        }
        _updateMapMarkers();
      },
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      onTap: (latLng) {
        setState(() => _selectedRide = null);
        _updateMapMarkers();
      },
    );
  }

  Widget _buildTopBar(bool isDark) {
    final user = AuthService.to.currentUser;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.location, color: AppColors.primaryYellow, size: 18),
                  const SizedBox(width: 8),
                  _isLoadingLocation
                      ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                    ),
                  )
                      : Text(
                    _currentCity,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _availableRides.isNotEmpty ? AppColors.online : AppColors.grey500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_availableRides.length} rides',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2, end: 0),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.3), blurRadius: 10)],
              ),
              child: Center(
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name.substring(0, 1).toUpperCase() : 'P',
                  style: GoogleFonts.urbanist(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBackground,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideX(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Positioned(
      top: 110,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
        ),
        child: Row(
          children: [
            const Icon(Iconsax.search_normal, color: AppColors.grey500),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by location or driver...',
                  hintStyle: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Iconsax.close_circle, color: AppColors.grey500, size: 20),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildActiveRideBanner(bool isDark) {
    final ride = _acceptedRide!;

    return Positioned(
      top: 175,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => Get.to(() => PassengerActiveRideScreen(ride: ride)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primaryYellow, AppColors.goldenYellow]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 2)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.car, color: AppColors.darkBackground, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.status == RideStatus.inProgress ? 'Ride in Progress' : 'Ride Accepted',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBackground,
                      ),
                    ),
                    Text(
                      'Driver: ${ride.driverName ?? 'Unknown'}',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        color: AppColors.darkBackground.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Iconsax.arrow_right_3, color: AppColors.darkBackground),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildPendingRequestBanner(bool isDark) {
    return Positioned(
      top: 175,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.info,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.info.withValues(alpha: 0.3), blurRadius: 10)],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Pending',
                    style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  Text(
                    'Waiting for driver response...',
                    style: GoogleFonts.urbanist(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _cancelRequest(_activeRequest!.id),
              child: Text(
                'Cancel',
                style: GoogleFonts.urbanist(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildMapControls(bool isDark) {
    return Positioned(
      right: 16,
      bottom: MediaQuery.of(context).size.height * 0.45,
      child: Column(
        children: [
          GestureDetector(
            onTap: _centerOnCurrentLocation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
              ),
              child: const Icon(Iconsax.gps, color: AppColors.primaryYellow, size: 22),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              setState(() => _isLoadingRides = true);
              _listenToAvailableRides();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
              ),
              child: const Icon(Iconsax.refresh, color: AppColors.grey500, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverPanel(bool isDark) {
    final topOffset = _acceptedRide != null || _activeRequest != null ? 0.32 : 0.38;

    return DraggableScrollableSheet(
      initialChildSize: topOffset,
      minChildSize: 0.15,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.grey500, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Available Rides',
                      style: GoogleFonts.urbanist(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_filteredRides.length}',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBackground,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tap marker on map',
                      style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingRides
                    ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                  ),
                )
                    : _filteredRides.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredRides.length,
                  itemBuilder: (context, index) {
                    final ride = _filteredRides[index];
                    final isSelected = _selectedRide?.id == ride.id;
                    return _RideCard(
                      ride: ride,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedRide = ride);
                        _updateMapMarkers();
                        _showOfferFareSheet(ride);
                      },
                      onChat: () => Get.to(
                            () => ChatScreen(userName: ride.driverName ?? 'Driver', isDriver: false),
                        transition: Transition.rightToLeftWithFade,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.car, size: 40, color: AppColors.primaryYellow),
          ),
          const SizedBox(height: 16),
          Text(
            'No Rides Available',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for available rides',
            style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// RIDE CARD WIDGET
// ==========================================

class _RideCard extends StatelessWidget {
  final RideModel ride;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onChat;

  const _RideCard({
    required this.ride,
    required this.isSelected,
    required this.onTap,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryYellow
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.2), blurRadius: 10)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          (ride.driverName ?? 'D').substring(0, 1).toUpperCase(),
                          style: GoogleFonts.urbanist(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBackground,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Iconsax.car, size: 10, color: AppColors.primaryYellow),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ride.driverName ?? 'Driver',
                              style: GoogleFonts.urbanist(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.grey900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Iconsax.star1, size: 10, color: AppColors.primaryYellow),
                                const SizedBox(width: 2),
                                Text(
                                  '4.8',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryYellow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${ride.carDetails.name} • ${ride.carDetails.number}',
                        style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onChat,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkElevated : AppColors.grey100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Iconsax.message, color: isDark ? Colors.white : AppColors.grey700, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground.withValues(alpha: 0.5) : AppColors.grey50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                      Container(width: 1, height: 20, color: AppColors.grey400),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.startLocation.address,
                          style: GoogleFonts.urbanist(fontSize: 12, color: isDark ? Colors.white : AppColors.grey900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ride.endLocation.address,
                          style: GoogleFonts.urbanist(fontSize: 12, color: isDark ? Colors.white : AppColors.grey900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stats
            Row(
              children: [
                _buildStat(Iconsax.user, '${ride.availableSeats}', isDark),
                const SizedBox(width: 16),
                _buildStat(Iconsax.location, '${ride.distance?.toStringAsFixed(1) ?? '0'} km', isDark),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Rs. ${ride.suggestedFare ?? 0}',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBackground,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.grey500),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.grey700,
          ),
        ),
      ],
    );
  }
}