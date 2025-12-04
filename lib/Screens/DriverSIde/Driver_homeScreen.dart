import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routelink/Screens/DriverSIde/DriverCHatSCreen.dart';
import 'package:routelink/Screens/DriverSIde/DriverRIdeHistory.dart';
import 'package:routelink/Screens/DriverSIde/DriverROuteScreen.dart';
import 'package:routelink/Screens/DriverSIde/DriverSetting_Screen.dart';
import 'package:routelink/Screens/PassengerSide/RideRequestcard.dart';
import '../../Core/Theme/App_theme.dart';
import '../../Models/Ride_model.dart';
import '../../Models/Ride_request_model.dart';
import '../../Services/Firebase Auth.dart';
import '../Chat/Chat_Screen.dart';
import 'Driver_BottomNav.dart';
import 'RideRequest.dart';
import 'RouteSetup.dart';
import 'ActiveRideScreen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DriverHomeContent(),
          DriverRoutesScreen(),
          DriverChatsScreen(),
          DriverRideHistoryScreen(),
          DriverSettingsScreen(),
        ],
      ),
      bottomNavigationBar: DriverBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

class _DriverHomeContent extends StatefulWidget {
  const _DriverHomeContent();

  @override
  State<_DriverHomeContent> createState() => _DriverHomeContentState();
}

class _DriverHomeContentState extends State<_DriverHomeContent> {
  // Google Maps Controller
  GoogleMapController? _mapController;

  // Current location
  Position? _currentPosition;
  LatLng? _currentLatLng;

  // City name (auto-detected)
  String _currentCity = 'Detecting...';

  // Map markers and polylines
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Active ride
  RideModel? _activeRide;
  bool _isLoading = true;
  bool _isLocationLoading = true;

  // Time display
  String _currentTime = '';
  Timer? _timer;
  Timer? _locationTimer;

  // Stream subscriptions
  StreamSubscription<Position>? _positionStream;

  // Map style for dark mode
  String? _darkMapStyle;
  String? _lightMapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyles();
    _initializeLocation();
    _checkActiveRide();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationTimer?.cancel();
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _loadMapStyles() {
    _darkMapStyle = '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
      {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
      {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#757575"}]},
      {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#181818"}]},
      {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
      {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c2c"}]},
      {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8a8a8a"}]},
      {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#373737"}]},
      {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3c3c3c"}]},
      {"featureType": "road.highway.controlled_access", "elementType": "geometry", "stylers": [{"color": "#4e4e4e"}]},
      {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
      {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]},
      {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#3d3d3d"}]}
    ]
    ''';
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLocationLoading = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Location Disabled',
        'Please enable location services',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      setState(() => _isLocationLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Permission Denied',
          'Location permission is required',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        setState(() => _isLocationLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Permission Denied',
        'Please enable location permission in settings',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      setState(() => _isLocationLoading = false);
      return;
    }

    try {
      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLatLng = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // Update marker
      _updateCurrentLocationMarker();

      // Auto-detect city (simplified - you can use geocoding API for accurate city name)
      _detectCity();

      setState(() => _isLocationLoading = false);

      // Start listening to location updates
      _startLocationStream();

    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _isLocationLoading = false);
    }
  }

  void _startLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        _currentPosition = position;
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _updateCurrentLocationMarker();
      });

      // Animate camera to new position
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentLatLng!),
      );
    });
  }

  void _updateCurrentLocationMarker() {
    if (_currentLatLng == null) return;

    _markers = {
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: _currentCity,
        ),
      ),
    };
    setState(() {});
  }

  void _detectCity() {
    // For Pakistan, using approximate coordinates
    // In production, use Google Geocoding API or similar
    if (_currentPosition != null) {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;

      // Approximate city detection based on coordinates
      if (lat >= 31.4 && lat <= 31.7 && lng >= 74.2 && lng <= 74.5) {
        _currentCity = 'Lahore';
      } else if (lat >= 33.5 && lat <= 33.8 && lng >= 72.8 && lng <= 73.3) {
        _currentCity = 'Islamabad';
      } else if (lat >= 24.8 && lat <= 25.0 && lng >= 66.9 && lng <= 67.2) {
        _currentCity = 'Karachi';
      } else if (lat >= 31.3 && lat <= 31.6 && lng >= 73.0 && lng <= 73.3) {
        _currentCity = 'Faisalabad';
      } else {
        _currentCity = 'Your City';
      }
      setState(() {});
    }
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5)); // PKT is UTC+5
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  void _checkActiveRide() async {
    final userId = AuthService.to.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    FirebaseFirestore.instance
        .collection('rides')
        .where('driverId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'accepted', 'inProgress'])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _activeRide = RideModel.fromJson({
            'id': snapshot.docs.first.id,
            ...snapshot.docs.first.data(),
          });
          _isLoading = false;
        });
        // Update route on map if active ride exists
        _updateRouteOnMap();
      } else {
        setState(() {
          _activeRide = null;
          _isLoading = false;
          // Clear route polylines when no active ride
          _polylines.clear();
        });
      }
    });
  }

  void _updateRouteOnMap() {
    if (_activeRide == null) return;

    final startLatLng = LatLng(
      _activeRide!.startLocation.latitude,
      _activeRide!.startLocation.longitude,
    );
    final endLatLng = LatLng(
      _activeRide!.endLocation.latitude,
      _activeRide!.endLocation.longitude,
    );

    // Update markers
    _markers = {
      if (_currentLatLng != null)
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      Marker(
        markerId: const MarkerId('start'),
        position: startLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup',
          snippet: _activeRide!.startLocation.address,
        ),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: endLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Drop-off',
          snippet: _activeRide!.endLocation.address,
        ),
      ),
    };

    // Add polyline for route
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [startLatLng, endLatLng],
        color: AppColors.primaryYellow,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };

    setState(() {});

    // Fit bounds to show entire route
    _fitBounds(startLatLng, endLatLng);
  }

  void _fitBounds(LatLng start, LatLng end) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        start.latitude < end.latitude ? start.latitude : end.latitude,
        start.longitude < end.longitude ? start.longitude : end.longitude,
      ),
      northeast: LatLng(
        start.latitude > end.latitude ? start.latitude : end.latitude,
        start.longitude > end.longitude ? start.longitude : end.longitude,
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _showRouteSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteSetupSheet(
        currentCity: _currentCity,
        currentLatLng: _currentLatLng,
        onPublish: (startLocation, endLocation, carDetails, seats, fare) {
          Navigator.pop(context);
          _publishRoute(startLocation, endLocation, carDetails, seats, fare);
        },
      ),
    );
  }

  Future<void> _publishRoute(
      LocationPoint startLocation,
      LocationPoint endLocation,
      CarDetails carDetails,
      int seats,
      int? fare,
      ) async {
    final userId = AuthService.to.currentUser?.uid;
    final userName = AuthService.to.currentUser?.name;

    if (userId == null) return;

    try {
      final rideData = {
        'driverId': userId,
        'driverName': userName,
        'startLocation': startLocation.toJson(),
        'endLocation': endLocation.toJson(),
        'viaPoints': [],
        'carDetails': carDetails.toJson(),
        'availableSeats': seats,
        'suggestedFare': fare,
        'status': 'active',
        'city': _currentCity,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance.collection('rides').add(rideData);

      Get.snackbar(
        'Route Published!',
        'Your route is now visible to passengers in $_currentCity',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to publish route: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentLatLng != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLatLng!,
            zoom: 16,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Google Map
          _buildGoogleMap(isDark),

          // Top Bar
          _buildTopBar(isDark),

          // City Badge
          _buildCityBadge(isDark),

          // Status Card (when route is active)
          if (_activeRide != null && _activeRide!.status == RideStatus.active)
            _buildStatusCard(isDark),

          // Active Ride Banner
          if (_activeRide != null &&
              (_activeRide!.status == RideStatus.inProgress ||
                  _activeRide!.status == RideStatus.accepted))
            _buildActiveRideBanner(isDark),

          // Requests Panel (when route is active)
          if (_activeRide != null && _activeRide!.status == RideStatus.active)
            _buildRequestsPanel(isDark),

          // Set Route FAB
          if (_activeRide == null && !_isLoading)
            _buildSetRouteFAB(isDark),

          // Center Location Button
          _buildCenterLocationButton(isDark),

          // Loading Overlay
          if (_isLoading || _isLocationLoading)
            _buildLoadingOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildGoogleMap(bool isDark) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLatLng ?? const LatLng(31.5204, 74.3587), // Default: Lahore
        zoom: 15,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        if (isDark && _darkMapStyle != null) {
          _mapController!.setMapStyle(_darkMapStyle);
        }
        // Center on current location when map is ready
        if (_currentLatLng != null) {
          _centerOnCurrentLocation();
        }
      },
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      trafficEnabled: false,
    );
  }

  Widget _buildTopBar(bool isDark) {
    final user = AuthService.to.currentUser;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Time display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Icon(Iconsax.clock, color: AppColors.primaryYellow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _currentTime,
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),

            const Spacer(),

            // Online/Offline status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _activeRide != null ? AppColors.online : AppColors.grey500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _activeRide != null ? 'Online' : 'Offline',
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

            // Profile avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primaryYellow.withOpacity(0.3), blurRadius: 10)],
              ),
              child: Center(
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name.substring(0, 1).toUpperCase()
                      : 'D',
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

  Widget _buildCityBadge(bool isDark) {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryYellow,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryYellow.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.location, color: AppColors.darkBackground, size: 18),
              const SizedBox(width: 8),
              Text(
                _currentCity,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBackground,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: -0.3, end: 0),
      ),
    );
  }

  Widget _buildCenterLocationButton(bool isDark) {
    return Positioned(
      right: 16,
      bottom: _activeRide != null ? 400 : 200,
      child: GestureDetector(
        onTap: _centerOnCurrentLocation,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
          ),
          child: Icon(
            Iconsax.gps,
            color: AppColors.primaryYellow,
            size: 24,
          ),
        ),
      ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    return Positioned(
      top: 140,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.routing, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Active',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                  Text(
                    '${_activeRide!.startLocation.address.split(',').first} → ${_activeRide!.endLocation.address.split(',').first}',
                    style: GoogleFonts.urbanist(fontSize: 13, color: AppColors.grey500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _endRoute(),
              child: Text(
                'End',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildActiveRideBanner(bool isDark) {
    return Positioned(
      top: 140,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => Get.to(() => ActiveRideScreen(ride: _activeRide!)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryYellow, AppColors.goldenYellow],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryYellow.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground.withOpacity(0.2),
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
                      _activeRide!.status == RideStatus.inProgress
                          ? 'Ride in Progress'
                          : 'Ride Accepted',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBackground,
                      ),
                    ),
                    Text(
                      'Passenger: ${_activeRide!.passengerName ?? 'Unknown'}',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        color: AppColors.darkBackground.withOpacity(0.7),
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

  Widget _buildRequestsPanel(bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey500,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Ride Requests',
                      style: GoogleFonts.urbanist(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('ride_requests')
                          .where('rideId', isEqualTo: _activeRide?.id)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkBackground,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ride_requests')
                      .where('rideId', isEqualTo: _activeRide?.id)
                      .where('status', isEqualTo: 'pending')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                        ),
                      );
                    }

                    final requests = snapshot.data?.docs ?? [];

                    if (requests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.user_search, size: 48, color: AppColors.grey500),
                            const SizedBox(height: 16),
                            Text(
                              'No requests yet',
                              style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
                            ),
                            Text(
                              'Waiting for passengers in $_currentCity...',
                              style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final requestData = requests[index].data() as Map<String, dynamic>;
                        final request = RideRequestModel.fromJson({
                          'id': requests[index].id,
                          ...requestData,
                        });
                        return RideRequestCard(
                          request: {
                            'id': request.id,
                            'name': request.passengerName,
                            'pickup': request.pickupAddress,
                            'dropoff': request.dropoffAddress,
                            'offeredFare': request.offeredFare,
                            'distance': '${request.distance?.toStringAsFixed(1) ?? '0'} km',
                            'rating': request.passengerRating,
                          },
                          onAccept: () => _acceptRequest(request),
                          onReject: () => _rejectRequest(request.id),
                          onChat: () =>  Get.to(() => ChatScreen(
                          userName: request.passengerName,
                          isDriver: true,
                          recipientId: request.passengerId, // Add passenger ID here
                        )),
                        ).animate()
                            .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                            .slideX(begin: 0.1, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetRouteFAB(bool isDark) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: ElevatedButton(
        onPressed: _showRouteSetup,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.darkBackground,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: AppColors.primaryYellow.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.routing_2, size: 24),
            const SizedBox(width: 12),
            Text(
              'Set Your Route in $_currentCity',
              style: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return Container(
      color: (isDark ? AppColors.darkBackground : AppColors.lightBackground).withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
            ),
            const SizedBox(height: 20),
            Text(
              _isLocationLoading ? 'Getting your location...' : 'Loading...',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptRequest(RideRequestModel request) async {
    try {
      await FirebaseFirestore.instance.collection('ride_requests').doc(request.id).update({
        'status': 'accepted',
        'respondedAt': DateTime.now().toIso8601String(),
      });

      await FirebaseFirestore.instance.collection('rides').doc(_activeRide!.id).update({
        'status': 'accepted',
        'passengerId': request.passengerId,
        'passengerName': request.passengerName,
        'acceptedFare': request.offeredFare,
      });

      // Reject other pending requests
      final otherRequests = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('rideId', isEqualTo: _activeRide!.id)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in otherRequests.docs) {
        await doc.reference.update({
          'status': 'rejected',
          'respondedAt': DateTime.now().toIso8601String(),
        });
      }

      Get.snackbar(
        'Request Accepted!',
        'You accepted ${request.passengerName}\'s request',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to accept request: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _rejectRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('ride_requests').doc(requestId).update({
        'status': 'rejected',
        'respondedAt': DateTime.now().toIso8601String(),
      });

      Get.snackbar(
        'Request Rejected',
        'The request has been rejected',
        backgroundColor: AppColors.grey700,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reject request: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _endRoute() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'End Route',
          style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to end this route?',
          style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.urbanist(fontWeight: FontWeight.w600, color: AppColors.grey500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                await FirebaseFirestore.instance.collection('rides').doc(_activeRide!.id).update({
                  'status': 'cancelled',
                });

                // Cancel pending requests
                final requests = await FirebaseFirestore.instance
                    .collection('ride_requests')
                    .where('rideId', isEqualTo: _activeRide!.id)
                    .where('status', isEqualTo: 'pending')
                    .get();

                for (var doc in requests.docs) {
                  await doc.reference.update({'status': 'cancelled'});
                }

                // Clear route from map
                setState(() {
                  _polylines.clear();
                  _updateCurrentLocationMarker();
                });

                Get.snackbar(
                  'Route Ended',
                  'Your route has been cancelled',
                  backgroundColor: AppColors.grey700,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to end route: $e',
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'End Route',
              style: GoogleFonts.urbanist(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}