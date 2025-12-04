import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:routelink/Core/Theme/App_theme.dart';
import '../../Models/Ride_model.dart';
import '../../Services/Firebase Auth.dart';
import '../Chat/Chat_Screen.dart';

/// ============================================
/// PASSENGER ACTIVE RIDE SCREEN
/// Real-time ride tracking with Google Maps
/// ============================================

class PassengerActiveRideScreen extends StatefulWidget {
  final RideModel ride;
  const PassengerActiveRideScreen({super.key, required this.ride});

  @override
  State<PassengerActiveRideScreen> createState() => _PassengerActiveRideScreenState();
}

class _PassengerActiveRideScreenState extends State<PassengerActiveRideScreen>
    with TickerProviderStateMixin {
  late RideModel _ride;
  StreamSubscription? _rideSubscription;
  StreamSubscription? _locationSubscription;
  late AnimationController _pulseController;
  double _rideProgress = 0.0;

  // Google Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routeCoordinates = [];

  // Driver's live location
  LatLng? _driverLocation;
  DateTime? _lastLocationUpdate;
  double _driverBearing = 0.0;

  // ETA
  String _eta = 'Calculating...';
  String _distanceText = '--';
  bool _isMapLoading = true;

  // TODO: Replace with your Google Maps API Key
  static const String _googleApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _listenToRideUpdates();
    _listenToDriverLocation();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _locationSubscription?.cancel();
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _listenToRideUpdates() {
    _rideSubscription = FirebaseFirestore.instance
        .collection('rides')
        .doc(_ride.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _ride = RideModel.fromJson({'id': snapshot.id, ...snapshot.data()!});
        });
        if (_ride.status == RideStatus.completed) {
          _showCompletionDialog();
        } else if (_ride.status == RideStatus.cancelled) {
          Get.back();
          Get.snackbar('Ride Cancelled', 'The driver has cancelled this ride',
              backgroundColor: AppColors.error, colorText: Colors.white,
              snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(16), borderRadius: 12);
        }
      }
    });
  }

  void _listenToDriverLocation() {
    _locationSubscription = FirebaseDatabase.instance
        .ref('ride_locations/${_ride.id}')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final newLat = data['latitude']?.toDouble();
        final newLng = data['longitude']?.toDouble();

        if (newLat != null && newLng != null) {
          final newLocation = LatLng(newLat, newLng);

          // Calculate bearing from location change for smooth movement
          if (_driverLocation != null) {
            final distance = _calculateDistanceKm(_driverLocation!, newLocation);
            // Only update bearing if movement is significant (> 5 meters)
            if (distance > 0.005) {
              _driverBearing = _calculateBearing(_driverLocation!, newLocation);
            }
          }

          setState(() {
            _driverLocation = newLocation;
            _lastLocationUpdate = DateTime.now();
          });

          _updateDriverMarker();
          _calculateProgress();
          _calculateETA();
          _updateRoutePolyline();
        }
      }
    });
  }

  // ============ MAP FUNCTIONS ============

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setMapStyle();
    _initializeMapElements();
  }

  Future<void> _setMapStyle() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) _mapController?.setMapStyle(_darkMapStyle);
  }

  Future<void> _initializeMapElements() async {
    await _addStaticMarkers();
    await _drawRoute();
    _fitAllMarkers();
    setState(() => _isMapLoading = false);
  }

  Future<void> _addStaticMarkers() async {
    final pickupLatLng = LatLng(_ride.startLocation.latitude, _ride.startLocation.longitude);
    final dropoffLatLng = LatLng(_ride.endLocation.latitude, _ride.endLocation.longitude);

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Pickup', snippet: _ride.startLocation.address),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Drop-off', snippet: _ride.endLocation.address),
        ),
      };
    });
  }

  void _updateDriverMarker() {
    if (_driverLocation == null) return;

    // Find closest route segment to calculate proper bearing
    if (_routeCoordinates.length > 1) {
      int closestIndex = 0;
      double minDistance = double.infinity;
      for (int i = 0; i < _routeCoordinates.length; i++) {
        double dist = _calculateDistanceKm(_driverLocation!, _routeCoordinates[i]);
        if (dist < minDistance) {
          minDistance = dist;
          closestIndex = i;
        }
      }

      // Update bearing based on route direction at closest point
      if (closestIndex < _routeCoordinates.length - 1) {
        _driverBearing = _calculateBearing(_routeCoordinates[closestIndex], _routeCoordinates[closestIndex + 1]);
      }
    }

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _driverLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        rotation: _driverBearing,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        infoWindow: InfoWindow(
          title: _ride.driverName ?? 'Driver',
          snippet: '${_ride.carDetails.name} • ${_ride.carDetails.number}',
        ),
      ));
    });
  }

  Future<void> _drawRoute() async {
    try {
      final pickupLatLng = LatLng(_ride.startLocation.latitude, _ride.startLocation.longitude);
      final dropoffLatLng = LatLng(_ride.endLocation.latitude, _ride.endLocation.longitude);

      PolylinePoints polylinePoints = PolylinePoints(apiKey: 'AIzaSyBf_uxaitv3XvVHTSPZHGa20C6q6U8IkkE');
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(pickupLatLng.latitude, pickupLatLng.longitude),
          destination: PointLatLng(dropoffLatLng.latitude, dropoffLatLng.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        _routeCoordinates = result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
        setState(() {
          _polylines.add(Polyline(
            polylineId: const PolylineId('main_route'),
            points: _routeCoordinates,
            color: AppColors.primaryYellow,
            width: 5,
            geodesic: true,
          ));
        });
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
      _drawStraightRoute();
    }
  }

  void _drawStraightRoute() {
    final pickupLatLng = LatLng(_ride.startLocation.latitude, _ride.startLocation.longitude);
    final dropoffLatLng = LatLng(_ride.endLocation.latitude, _ride.endLocation.longitude);
    setState(() {
      _polylines.add(Polyline(
        polylineId: const PolylineId('main_route'),
        points: [pickupLatLng, dropoffLatLng],
        color: AppColors.primaryYellow,
        width: 5,
        geodesic: true,
      ));
    });
  }

  void _updateRoutePolyline() {
    if (_driverLocation == null || _routeCoordinates.isEmpty) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Find closest point on the route
    int closestIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < _routeCoordinates.length; i++) {
      double dist = _calculateDistanceKm(_driverLocation!, _routeCoordinates[i]);
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    // Calculate bearing for next segment to ensure proper direction
    if (closestIndex < _routeCoordinates.length - 1) {
      _driverBearing = _calculateBearing(_routeCoordinates[closestIndex], _routeCoordinates[closestIndex + 1]);
    }

    // Create route segments with driver position snapped to route
    final snappedDriverPosition = _snapToRoute(_driverLocation!, closestIndex);
    final completedRoute = _routeCoordinates.sublist(0, closestIndex + 1);
    if (snappedDriverPosition != null) {
      completedRoute.add(snappedDriverPosition);
    }

    final remainingRoute = snappedDriverPosition != null
        ? [snappedDriverPosition, ..._routeCoordinates.sublist(closestIndex + 1)]
        : _routeCoordinates.sublist(closestIndex);

    setState(() {
      _polylines = {
        if (completedRoute.length > 1)
          Polyline(
            polylineId: const PolylineId('completed'),
            points: completedRoute,
            color: isDark ? AppColors.grey600 : AppColors.grey400,
            width: 5,
            geodesic: true,
          ),
        if (remainingRoute.length > 1)
          Polyline(
            polylineId: const PolylineId('remaining'),
            points: remainingRoute,
            color: AppColors.primaryYellow,
            width: 5,
            geodesic: true,
          ),
      };
    });
  }

  // Snap driver location to the nearest point on the route segment
  LatLng? _snapToRoute(LatLng point, int closestIndex) {
    if (closestIndex >= _routeCoordinates.length - 1) return null;

    final segmentStart = _routeCoordinates[closestIndex];
    final segmentEnd = _routeCoordinates[closestIndex + 1];

    // Calculate the projection of the point onto the line segment
    final dx = segmentEnd.longitude - segmentStart.longitude;
    final dy = segmentEnd.latitude - segmentStart.latitude;

    if (dx == 0 && dy == 0) return segmentStart;

    final t = ((point.longitude - segmentStart.longitude) * dx +
        (point.latitude - segmentStart.latitude) * dy) /
        (dx * dx + dy * dy);

    // Clamp t to [0, 1] to stay within the segment
    final clampedT = t.clamp(0.0, 1.0);

    return LatLng(
      segmentStart.latitude + clampedT * dy,
      segmentStart.longitude + clampedT * dx,
    );
  }

  void _fitAllMarkers() {
    if (_mapController == null) return;
    List<LatLng> points = [
      LatLng(_ride.startLocation.latitude, _ride.startLocation.longitude),
      LatLng(_ride.endLocation.latitude, _ride.endLocation.longitude),
    ];
    if (_driverLocation != null) points.add(_driverLocation!);

    double minLat = points.map((p) => p.latitude).reduce(math.min);
    double maxLat = points.map((p) => p.latitude).reduce(math.max);
    double minLng = points.map((p) => p.longitude).reduce(math.min);
    double maxLng = points.map((p) => p.longitude).reduce(math.max);

    final latPad = (maxLat - minLat) * 0.15;
    final lngPad = (maxLng - minLng) * 0.15;

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat - latPad, minLng - lngPad),
        northeast: LatLng(maxLat + latPad, maxLng + lngPad),
      ),
      80,
    ));
  }

  void _centerOnDriver() {
    if (_mapController == null || _driverLocation == null) return;
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _driverLocation!, zoom: 16, bearing: _driverBearing),
    ));
  }

  // ============ CALCULATIONS ============

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * math.pi / 180;
    double lat2 = end.latitude * math.pi / 180;
    double dLon = (end.longitude - start.longitude) * math.pi / 180;
    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _calculateDistanceKm(LatLng start, LatLng end) {
    const double earthRadius = 6371;
    double dLat = (end.latitude - start.latitude) * math.pi / 180;
    double dLon = (end.longitude - start.longitude) * math.pi / 180;
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(start.latitude * math.pi / 180) * math.cos(end.latitude * math.pi / 180) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void _calculateProgress() {
    if (_driverLocation == null) return;
    final start = LatLng(_ride.startLocation.latitude, _ride.startLocation.longitude);
    final end = LatLng(_ride.endLocation.latitude, _ride.endLocation.longitude);
    final total = _calculateDistanceKm(start, end);
    final driven = _calculateDistanceKm(start, _driverLocation!);
    if (total > 0) setState(() => _rideProgress = (driven / total).clamp(0.0, 1.0));
  }

  void _calculateETA() {
    if (_driverLocation == null) return;
    LatLng target = _ride.status == RideStatus.accepted
        ? LatLng(_ride.startLocation.latitude, _ride.startLocation.longitude)
        : LatLng(_ride.endLocation.latitude, _ride.endLocation.longitude);

    double distKm = _calculateDistanceKm(_driverLocation!, target);
    double etaMin = (distKm / 30) * 60;

    setState(() {
      _distanceText = distKm < 1 ? '${(distKm * 1000).toInt()} m' : '${distKm.toStringAsFixed(1)} km';
      _eta = etaMin < 1 ? 'Arriving' : '${etaMin.toInt()} min';
    });
  }

  // ============ DIALOGS ============

  void _showCompletionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), shape: BoxShape.circle),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Iconsax.tick_circle, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 24),
            Text('Ride Completed! 🎉', style: GoogleFonts.urbanist(
                fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.grey900)),
            const SizedBox(height: 8),
            Text('Thank you for riding with RouteLink',
                style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.grey50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                _summaryRow('Distance', '${_ride.distance?.toStringAsFixed(1) ?? '0'} km', isDark),
                const SizedBox(height: 12),
                _summaryRow('Duration', '${_ride.estimatedDuration ?? 0} min', isDark),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                _summaryRow('Total Fare', 'Rs. ${_ride.acceptedFare ?? _ride.suggestedFare ?? 0}', isDark, highlighted: true),
              ]),
            ),
            const SizedBox(height: 24),
            Text('Rate your driver', style: GoogleFonts.urbanist(
                fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.grey900)),
            const SizedBox(height: 12),
            _RatingStars(onRatingSelected: (r) => debugPrint('Rating: $r')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Get.back(); Get.back(); },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow, foregroundColor: AppColors.darkBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: Text('Done', style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _summaryRow(String label, String value, bool isDark, {bool highlighted = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500)),
      Text(value, style: GoogleFonts.urbanist(
          fontSize: highlighted ? 20 : 14, fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
          color: highlighted ? AppColors.primaryYellow : (isDark ? Colors.white : AppColors.grey900))),
    ]);
  }

  Future<void> _cancelRide() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(children: [
        Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.danger, color: AppColors.error)),
        const SizedBox(width: 12),
        Text('Cancel Ride', style: GoogleFonts.urbanist(
            fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.grey900)),
      ]),
      content: Text('Are you sure you want to cancel this ride?',
          style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500)),
      actions: [
        TextButton(onPressed: () => Get.back(),
            child: Text('No', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600, color: AppColors.grey500))),
        ElevatedButton(
          onPressed: () async { Get.back(); await _performCancellation(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          child: Text('Yes, Cancel', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
        ),
      ],
    ));
  }

  Future<void> _performCancellation() async {
    try {
      await FirebaseFirestore.instance.collection('rides').doc(_ride.id).update({
        'status': 'active', 'passengerId': null, 'passengerName': null, 'acceptedFare': null,
      });
      await FirebaseDatabase.instance.ref('ride_locations/${_ride.id}').remove();
      Get.back();
      Get.snackbar('Ride Cancelled', 'Your ride has been cancelled',
          backgroundColor: AppColors.error, colorText: Colors.white,
          snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(16), borderRadius: 12);
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel: $e', backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(children: [
        // ========== GOOGLE MAP ==========
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(_ride.startLocation.latitude, _ride.startLocation.longitude),
            zoom: 14,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
        ),

        // Loading
        if (_isMapLoading)
          Container(
            color: isDark ? AppColors.darkBackground : Colors.white,
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: AppColors.primaryYellow),
              const SizedBox(height: 16),
              Text('Loading map...', style: GoogleFonts.urbanist(fontSize: 16,
                  color: isDark ? Colors.white70 : AppColors.grey600)),
            ])),
          ),

        // Top bar
        _buildTopBar(isDark),

        // Live badge
        if (_driverLocation != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16,
            child: _buildLiveBadge(isDark),
          ),

        // ETA card
        if (_driverLocation != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: _buildETACard(isDark),
          ),

        // Bottom panel
        _buildBottomPanel(isDark),
      ]),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 50, height: 50,
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
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _driverLocation != null ? _centerOnDriver : _fitAllMarkers,
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: const Icon(Iconsax.gps, color: AppColors.primaryYellow),
            ),
          ),
        ]),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatusBadge(bool isDark) {
    Color bg; Color txt; String text; IconData icon;
    switch (_ride.status) {
      case RideStatus.accepted:
        bg = AppColors.info; txt = Colors.white; text = 'Driver on the way'; icon = Iconsax.car; break;
      case RideStatus.inProgress:
        bg = AppColors.primaryYellow; txt = AppColors.darkBackground; text = 'Ride in Progress'; icon = Iconsax.routing_2; break;
      default:
        bg = AppColors.grey500; txt = Colors.white; text = 'Unknown'; icon = Iconsax.info_circle;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: bg.withOpacity(0.4), blurRadius: 12)]),
      child: Row(children: [
        Icon(icon, size: 18, color: txt),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
      ]),
    );
  }

  Widget _buildLiveBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (ctx, _) => Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: AppColors.online, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.online.withOpacity(_pulseController.value * 0.6),
                    blurRadius: 6, spreadRadius: 2)]),
          ),
        ),
        const SizedBox(width: 8),
        Text('Live', style: GoogleFonts.urbanist(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.online)),
      ]),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildETACard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(_ride.status == RideStatus.accepted ? 'Arriving in' : 'ETA',
            style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500)),
        const SizedBox(height: 4),
        Text(_eta, style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryYellow)),
        Text(_distanceText, style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500)),
      ]),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildBottomPanel(bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4, minChildSize: 0.25, maxChildSize: 0.7,
      builder: (ctx, sc) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SingleChildScrollView(
          controller: sc,
          child: Column(children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.grey500, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildDriverCard(isDark)),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildRouteCard(isDark)),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildStatsCard(isDark)),
            const SizedBox(height: 20),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildActions(isDark)),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  Widget _buildDriverCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(18)),
          child: Center(child: Text((_ride.driverName ?? 'D')[0].toUpperCase(),
              style: GoogleFonts.urbanist(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.darkBackground))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_ride.driverName ?? 'Driver', style: GoogleFonts.urbanist(
              fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.grey900)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Iconsax.star1, size: 14, color: AppColors.primaryYellow),
            const SizedBox(width: 4),
            Text('4.8', style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey500)),
            const SizedBox(width: 10),
            Flexible(child: Text('${_ride.carDetails.name} • ${_ride.carDetails.number}',
                style: GoogleFonts.urbanist(fontSize: 13, color: AppColors.grey500), overflow: TextOverflow.ellipsis)),
          ]),
        ])),
        Row(children: [
          _circleBtn(Iconsax.message, AppColors.info, () => Get.to(() => ChatScreen(
            userName: _ride.driverName ?? 'Driver', isDriver: false, recipientId: null,), transition: Transition.rightToLeftWithFade)),
          const SizedBox(width: 10),
          _circleBtn(Iconsax.call, AppColors.success, () => Get.snackbar('Calling...', 'Phone feature coming soon',
              backgroundColor: AppColors.info, colorText: Colors.white, snackPosition: SnackPosition.TOP)),
        ]),
      ]),
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
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
      child: Column(children: [
        _locationRow(AppColors.success, 'Pickup', _ride.startLocation.address, isDark),
        Padding(padding: const EdgeInsets.only(left: 5),
            child: Column(children: List.generate(3, (_) => Container(width: 2, height: 6,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(color: AppColors.grey500, borderRadius: BorderRadius.circular(1)))))),
        _locationRow(AppColors.error, 'Drop-off', _ride.endLocation.address, isDark),
      ]),
    );
  }

  Widget _locationRow(Color color, String label, String address, bool isDark) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500)),
        Text(address, style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.grey900), maxLines: 2, overflow: TextOverflow.ellipsis),
      ])),
    ]);
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primaryYellow.withOpacity(0.15), AppColors.primaryYellow.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _stat(Iconsax.location, '${_ride.distance?.toStringAsFixed(1) ?? '0'} km', 'Distance'),
        Container(width: 1, height: 40, color: AppColors.primaryYellow.withOpacity(0.3)),
        _stat(Iconsax.clock, '${_ride.estimatedDuration ?? 0} min', 'Duration'),
        Container(width: 1, height: 40, color: AppColors.primaryYellow.withOpacity(0.3)),
        _stat(Iconsax.money, 'Rs.${_ride.acceptedFare ?? _ride.suggestedFare ?? 0}', 'Fare', highlight: true),
      ]),
    );
  }

  Widget _stat(IconData icon, String value, String label, {bool highlight = false}) {
    return Column(children: [
      Icon(icon, size: 20, color: highlight ? AppColors.primaryYellow : AppColors.grey500),
      const SizedBox(height: 8),
      Text(value, style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w700,
          color: highlight ? AppColors.primaryYellow : null)),
      Text(label, style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500)),
    ]);
  }

  Widget _buildActions(bool isDark) {
    if (_ride.status == RideStatus.accepted) {
      return Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(children: [
            const Icon(Iconsax.car, color: AppColors.info, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('Driver is on the way to pick you up',
                style: GoogleFonts.urbanist(fontSize: 14, color: isDark ? Colors.white70 : AppColors.grey700))),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: _cancelRide,
          icon: const Icon(Iconsax.close_circle, size: 20),
          label: Text('Cancel Ride', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
      ]);
    }
    if (_ride.status == RideStatus.inProgress) {
      return Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Trip Progress', style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500)),
              Text('${(_rideProgress * 100).toInt()}%', style: GoogleFonts.urbanist(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryYellow)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                value: _rideProgress, backgroundColor: isDark ? AppColors.darkBorder : AppColors.grey200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow), minHeight: 8)),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => Get.snackbar('Emergency', 'Emergency services contacted',
              backgroundColor: AppColors.error, colorText: Colors.white),
          icon: const Icon(Iconsax.danger, size: 20),
          label: Text('Emergency', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
      ]);
    }
    return const SizedBox();
  }

  static const String _darkMapStyle = '''
  [{"elementType":"geometry","stylers":[{"color":"#242f3e"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},{"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},{"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}]
  ''';
}

// ============ RATING STARS ============
class _RatingStars extends StatefulWidget {
  final Function(int) onRatingSelected;
  const _RatingStars({required this.onRatingSelected});

  @override
  State<_RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<_RatingStars> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
      final idx = i + 1;
      return GestureDetector(
        onTap: () { setState(() => _rating = idx); widget.onRatingSelected(idx); },
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Iconsax.star1, size: 36, color: idx <= _rating ? AppColors.primaryYellow : AppColors.grey400)),
      );
    }));
  }
}