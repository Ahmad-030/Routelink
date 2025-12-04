import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../Core/Theme/App_theme.dart';
import '../../Models/Ride_model.dart';
import '../../Models/user_model.dart';
import '../../Services/Firebase Auth.dart';
import '../Chat/Chat_Screen.dart';

/// ============================================
/// ACTIVE RIDE SCREEN
/// Real-time ride tracking with Google Maps
/// ============================================

class ActiveRideScreen extends StatefulWidget {
  final RideModel ride;

  const ActiveRideScreen({super.key, required this.ride});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> with TickerProviderStateMixin {
  late RideModel _ride;
  Timer? _locationTimer;
  Position? _currentPosition;
  bool _isLoading = false;
  StreamSubscription? _rideSubscription;
  late AnimationController _pulseController;
  double _rideProgress = 0.0;

  // Google Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLatLng;

  // Route points for animation
  List<LatLng> _routePoints = [];
  int _currentRouteIndex = 0;

  // Map style for dark mode
  String? _darkMapStyle;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadMapStyles();
    _initializeMap();
    _listenToRideUpdates();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _rideSubscription?.cancel();
    _pulseController.dispose();
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
      {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c2c"}]},
      {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3c3c3c"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]}
    ]
    ''';
  }

  void _initializeMap() {
    final startLatLng = LatLng(
      _ride.startLocation.latitude,
      _ride.startLocation.longitude,
    );
    final endLatLng = LatLng(
      _ride.endLocation.latitude,
      _ride.endLocation.longitude,
    );

    // Create simple route points between start and end
    _routePoints = _createRoutePoints(startLatLng, endLatLng);

    // Set up markers
    _updateMapMarkers(startLatLng, endLatLng);

    // Set up polyline
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: AppColors.primaryYellow,
        width: 5,
      ),
    };
  }

  List<LatLng> _createRoutePoints(LatLng start, LatLng end) {
    // Create intermediate points for smoother route
    List<LatLng> points = [];
    const int steps = 20;

    for (int i = 0; i <= steps; i++) {
      double fraction = i / steps;
      double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      double lng = start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  void _updateMapMarkers(LatLng startLatLng, LatLng endLatLng) {
    _markers = {
      // Pickup marker
      Marker(
        markerId: const MarkerId('pickup'),
        position: startLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup',
          snippet: _ride.startLocation.address,
        ),
      ),
      // Drop-off marker
      Marker(
        markerId: const MarkerId('dropoff'),
        position: endLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Drop-off',
          snippet: _ride.endLocation.address,
        ),
      ),
    };

    // Add driver marker if we have current position
    if (_currentLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _currentLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'You'),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
  }

  void _listenToRideUpdates() {
    _rideSubscription = FirebaseFirestore.instance
        .collection('rides')
        .doc(_ride.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _ride = RideModel.fromJson({
            'id': snapshot.id,
            ...snapshot.data()!,
          });
        });

        if (_ride.status == RideStatus.completed || _ride.status == RideStatus.cancelled) {
          Get.back();
        }
      }
    });
  }

  void _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _currentLatLng = LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        _updateMapWithCurrentLocation();
        setState(() {});
      } catch (e) {
        debugPrint('Error getting location: $e');
      }

      _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          _currentPosition = position;
          _currentLatLng = LatLng(position.latitude, position.longitude);

          if (_ride.status == RideStatus.inProgress) {
            // Update location in Firebase
            await FirebaseDatabase.instance.ref('ride_locations/${_ride.id}').update({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': ServerValue.timestamp,
            });

            // Update progress
            _updateRideProgress();
          }

          _updateMapWithCurrentLocation();
          setState(() {});
        } catch (e) {
          debugPrint('Error updating location: $e');
        }
      });
    }
  }

  void _updateMapWithCurrentLocation() {
    if (_currentLatLng == null) return;

    final startLatLng = LatLng(
      _ride.startLocation.latitude,
      _ride.startLocation.longitude,
    );
    final endLatLng = LatLng(
      _ride.endLocation.latitude,
      _ride.endLocation.longitude,
    );

    _updateMapMarkers(startLatLng, endLatLng);

    // Animate camera to current location
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(_currentLatLng!),
    );
  }

  void _updateRideProgress() {
    if (_currentLatLng == null) return;

    final startLatLng = LatLng(
      _ride.startLocation.latitude,
      _ride.startLocation.longitude,
    );
    final endLatLng = LatLng(
      _ride.endLocation.latitude,
      _ride.endLocation.longitude,
    );

    // Calculate total distance
    final totalDistance = Geolocator.distanceBetween(
      startLatLng.latitude,
      startLatLng.longitude,
      endLatLng.latitude,
      endLatLng.longitude,
    );

    // Calculate distance from start to current position
    final traveledDistance = Geolocator.distanceBetween(
      startLatLng.latitude,
      startLatLng.longitude,
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
    );

    // Calculate progress
    _rideProgress = (traveledDistance / totalDistance).clamp(0.0, 1.0);
  }

  void _fitMapBounds() {
    if (_mapController == null) return;

    final startLatLng = LatLng(
      _ride.startLocation.latitude,
      _ride.startLocation.longitude,
    );
    final endLatLng = LatLng(
      _ride.endLocation.latitude,
      _ride.endLocation.longitude,
    );

    final bounds = LatLngBounds(
      southwest: LatLng(
        startLatLng.latitude < endLatLng.latitude ? startLatLng.latitude : endLatLng.latitude,
        startLatLng.longitude < endLatLng.longitude ? startLatLng.longitude : endLatLng.longitude,
      ),
      northeast: LatLng(
        startLatLng.latitude > endLatLng.latitude ? startLatLng.latitude : endLatLng.latitude,
        startLatLng.longitude > endLatLng.longitude ? startLatLng.longitude : endLatLng.longitude,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  Future<void> _startRide() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('rides').doc(_ride.id).update({
        'status': 'inProgress',
        'startedAt': DateTime.now().toIso8601String(),
      });

      if (_currentPosition != null) {
        await FirebaseDatabase.instance.ref('ride_locations/${_ride.id}').set({
          'driverId': _ride.driverId,
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'timestamp': ServerValue.timestamp,
        });
      }

      Get.snackbar(
        'Ride Started! 🚗',
        'Drive safely to the destination',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start ride: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _endRide() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.tick_circle, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Text(
              'Complete Ride',
              style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to complete this ride?',
              style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fare Amount',
                    style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
                  ),
                  Text(
                    'Rs. ${_ride.acceptedFare ?? _ride.suggestedFare ?? 0}',
                    style: GoogleFonts.urbanist(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.urbanist(fontWeight: FontWeight.w600, color: AppColors.grey500),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              setState(() => _isLoading = true);

              try {
                await FirebaseFirestore.instance.collection('rides').doc(_ride.id).update({
                  'status': 'completed',
                  'completedAt': DateTime.now().toIso8601String(),
                });

                await FirebaseDatabase.instance.ref('ride_locations/${_ride.id}').remove();

                final userId = AuthService.to.currentUser?.uid;
                if (userId != null) {
                  await FirebaseFirestore.instance.collection('users').doc(userId).update({
                    'totalRides': FieldValue.increment(1),
                  });
                }

                Get.back();
                _showCompletionDialog();
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to end ride: $e',
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );
              }

              setState(() => _isLoading = false);
            },
            icon: const Icon(Iconsax.tick_circle, size: 18),
            label: Text('Complete', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.tick_circle, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ride Completed! 🎉',
              style: GoogleFonts.urbanist(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for using RouteLink',
              style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.grey50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Distance', '${_ride.distance?.toStringAsFixed(1) ?? '0'} km'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Duration', '${_ride.estimatedDuration ?? 0} min'),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Earned',
                    'Rs. ${_ride.acceptedFare ?? _ride.suggestedFare ?? 0}',
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.darkBackground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500)),
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            color: isHighlighted ? AppColors.primaryYellow : null,
          ),
        ),
      ],
    );
  }

  Future<void> _cancelRide() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.danger, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Text(
              'Cancel Ride',
              style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this ride? This may affect your rating.',
          style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'No, Keep Ride',
              style: GoogleFonts.urbanist(fontWeight: FontWeight.w600, color: AppColors.grey500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              setState(() => _isLoading = true);

              try {
                await FirebaseFirestore.instance.collection('rides').doc(_ride.id).update({
                  'status': 'cancelled',
                });
                await FirebaseDatabase.instance.ref('ride_locations/${_ride.id}').remove();

                Get.back();
                Get.snackbar(
                  'Ride Cancelled',
                  'The ride has been cancelled',
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to cancel ride: $e',
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );
              }

              setState(() => _isLoading = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Yes, Cancel', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDriver = AuthService.to.currentUser?.role == UserRole.driver;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Google Map
          _buildGoogleMap(isDark),

          // Top Bar
          _buildTopBar(isDark),

          // Ride Info Panel
          _buildRideInfoPanel(isDark, isDriver),

          // Loading Overlay
          if (_isLoading) _buildLoadingOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildGoogleMap(bool isDark) {
    final startLatLng = LatLng(
      _ride.startLocation.latitude,
      _ride.startLocation.longitude,
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLatLng ?? startLatLng,
        zoom: 15,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        if (isDark && _darkMapStyle != null) {
          _mapController!.setMapStyle(_darkMapStyle);
        }
        // Fit map to show entire route
        Future.delayed(const Duration(milliseconds: 500), _fitMapBounds);
      },
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
    );
  }

  Widget _buildTopBar(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Icon(Iconsax.arrow_left, color: isDark ? Colors.white : AppColors.grey900),
              ),
            ),
            const Spacer(),
            _buildStatusBadge(isDark),
            const SizedBox(width: 12),
            // Fit bounds button
            GestureDetector(
              onTap: _fitMapBounds,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: const Icon(Iconsax.maximize_4, color: AppColors.primaryYellow),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatusBadge(bool isDark) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    switch (_ride.status) {
      case RideStatus.accepted:
        bgColor = AppColors.info;
        textColor = Colors.white;
        text = 'Ready to Start';
        icon = Iconsax.tick_circle;
        break;
      case RideStatus.inProgress:
        bgColor = AppColors.primaryYellow;
        textColor = AppColors.darkBackground;
        text = 'In Progress';
        icon = Iconsax.car;
        break;
      default:
        bgColor = AppColors.grey500;
        textColor = Colors.white;
        text = 'Unknown';
        icon = Iconsax.info_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildRideInfoPanel(bool isDark, bool isDriver) {
    return DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.25,
      maxChildSize: 0.65,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
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
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildUserCard(isDark, isDriver),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildRouteCard(isDark),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatsCard(isDark),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildActionButtons(isDark, isDriver),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserCard(bool isDark, bool isDriver) {
    final otherUserName = isDriver ? _ride.passengerName : _ride.driverName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                (otherUserName ?? 'U').substring(0, 1).toUpperCase(),
                style: GoogleFonts.urbanist(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBackground,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUserName ?? (isDriver ? 'Passenger' : 'Driver'),
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Iconsax.star1, size: 14, color: AppColors.primaryYellow),
                    const SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey500,
                      ),
                    ),
                    if (!isDriver) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.grey500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _ride.carDetails.name,
                        style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildCircleButton(
                icon: Iconsax.message,
                color: AppColors.info,
                onTap: () => Get.to(() => ChatScreen(
                  userName: otherUserName ?? 'User',
                  isDriver: isDriver, recipientId: null,
                )),
              ),
              const SizedBox(width: 10),
              _buildCircleButton(
                icon: Iconsax.call,
                color: AppColors.success,
                onTap: () => Get.snackbar(
                  'Calling...',
                  'Phone feature coming soon',
                  backgroundColor: AppColors.info,
                  colorText: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildRouteCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pickup', style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500)),
                    Text(
                      _ride.startLocation.address,
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Column(
              children: List.generate(
                3,
                    (i) => Container(
                  width: 2,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.grey500,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Drop-off', style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500)),
                    Text(
                      _ride.endLocation.address,
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryYellow.withOpacity(0.15),
            AppColors.primaryYellow.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Iconsax.location,
            value: '${_ride.distance?.toStringAsFixed(1) ?? '0'} km',
            label: 'Distance',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.primaryYellow.withOpacity(0.3),
          ),
          _buildStatItem(
            icon: Iconsax.clock,
            value: '${_ride.estimatedDuration ?? 0} min',
            label: 'Duration',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.primaryYellow.withOpacity(0.3),
          ),
          _buildStatItem(
            icon: Iconsax.money,
            value: 'Rs.${_ride.acceptedFare ?? _ride.suggestedFare ?? 0}',
            label: 'Fare',
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: isHighlighted ? AppColors.primaryYellow : AppColors.grey500),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isHighlighted ? AppColors.primaryYellow : null,
          ),
        ),
        Text(label, style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500)),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark, bool isDriver) {
    if (!isDriver) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _cancelRide,
          icon: const Icon(Iconsax.close_circle, size: 20),
          label: Text('Cancel Ride', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    if (_ride.status == RideStatus.accepted) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startRide,
              icon: const Icon(Iconsax.play, size: 22),
              label: Text(
                'Start Ride',
                style: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _cancelRide,
            child: Text(
              'Cancel Ride',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      );
    }

    if (_ride.status == RideStatus.inProgress) {
      return Column(
        children: [
          // Progress indicator
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trip Progress',
                      style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
                    ),
                    Text(
                      '${(_rideProgress * 100).toInt()}%',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _rideProgress,
                    backgroundColor: isDark ? AppColors.darkBorder : AppColors.grey200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _endRide,
              icon: const Icon(Iconsax.tick_circle, size: 22),
              label: Text(
                'Complete Ride',
                style: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: AppColors.darkBackground,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _cancelRide,
            child: Text(
              'Cancel Ride',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Please wait...',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}