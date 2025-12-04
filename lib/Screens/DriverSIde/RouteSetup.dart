import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import '../../Core/Theme/App_theme.dart';
import '../../Models/Ride_model.dart';

typedef OnPublishCallback = void Function(
    LocationPoint startLocation,
    LocationPoint endLocation,
    CarDetails carDetails,
    int seats,
    int? fare,
    );

class RouteSetupSheet extends StatefulWidget {
  final OnPublishCallback onPublish;
  final String currentCity;
  final LatLng? currentLatLng;

  const RouteSetupSheet({
    super.key,
    required this.onPublish,
    required this.currentCity,
    this.currentLatLng,
  });

  @override
  State<RouteSetupSheet> createState() => _RouteSetupSheetState();
}

class _RouteSetupSheetState extends State<RouteSetupSheet> {
  final _startController = TextEditingController();
  final _destinationController = TextEditingController();
  final _carNameController = TextEditingController();
  final _carNumberController = TextEditingController();
  final _fareController = TextEditingController();

  int _availableSeats = 3;
  int _currentStep = 0;

  // Google Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Route coordinates
  LatLng? _startLatLng;
  LatLng? _endLatLng;
  List<LatLng> _routePoints = [];

  // Selection mode
  bool _selectingStart = true;
  bool _isLoadingRoute = false;
  bool _isSearching = false;

  // Route info
  String? _distance;
  String? _duration;

  // Search results
  List<PlacePrediction> _searchResults = [];
  bool _showSearchResults = false;
  String _activeSearchField = 'start';

  // Focus nodes
  final _startFocusNode = FocusNode();
  final _endFocusNode = FocusNode();

  // YOUR GOOGLE MAPS API KEY
  static const String _googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  String? _darkMapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();

    if (widget.currentLatLng != null) {
      _startLatLng = widget.currentLatLng;
      _startController.text = 'Current Location';
      _updateMarkers();
    }

    _startFocusNode.addListener(() {
      if (_startFocusNode.hasFocus) {
        _activeSearchField = 'start';
      }
    });
    _endFocusNode.addListener(() {
      if (_endFocusNode.hasFocus) {
        _activeSearchField = 'end';
      }
    });
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

  @override
  void dispose() {
    _startController.dispose();
    _destinationController.dispose();
    _carNameController.dispose();
    _carNumberController.dispose();
    _fareController.dispose();
    _mapController?.dispose();
    _startFocusNode.dispose();
    _endFocusNode.dispose();
    super.dispose();
  }

  void _updateMarkers() {
    _markers.clear();

    if (_startLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: _startLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup Point',
            snippet: _startController.text,
          ),
          draggable: true,
          onDragEnd: (newPosition) async {
            _startLatLng = newPosition;
            _startController.text = await _getAddressFromLatLng(newPosition);
            _updateMarkers();
            if (_endLatLng != null) {
              await _getDirections();
            }
          },
        ),
      );
    }

    if (_endLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: _endLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Drop-off Point',
            snippet: _destinationController.text,
          ),
          draggable: true,
          onDragEnd: (newPosition) async {
            _endLatLng = newPosition;
            _destinationController.text = await _getAddressFromLatLng(newPosition);
            _updateMarkers();
            if (_startLatLng != null) {
              await _getDirections();
            }
          },
        ),
      );
    }

    setState(() {});
  }

  void _onMapTap(LatLng position) async {
    setState(() => _showSearchResults = false);

    if (_selectingStart) {
      _startLatLng = position;
      _startController.text = await _getAddressFromLatLng(position);
    } else {
      _endLatLng = position;
      _destinationController.text = await _getAddressFromLatLng(position);
    }

    _updateMarkers();

    if (_startLatLng != null && _endLatLng != null) {
      await _getDirections();
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final locationBias = widget.currentLatLng != null
          ? '&location=${widget.currentLatLng!.latitude},${widget.currentLatLng!.longitude}&radius=50000'
          : '';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
            'input=$query'
            '&components=country:pk'
            '$locationBias'
            '&key=$_googleMapsApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['predictions'] != null) {
          setState(() {
            _searchResults = (data['predictions'] as List)
                .map((p) => PlacePrediction(
              placeId: p['place_id'],
              description: p['description'],
              mainText: p['structured_formatting']['main_text'],
              secondaryText: p['structured_formatting']['secondary_text'] ?? '',
            ))
                .toList();
            _showSearchResults = _searchResults.isNotEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }

    setState(() => _isSearching = false);
  }

  Future<LatLng?> _getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?'
            'place_id=$placeId'
            '&fields=geometry'
            '&key=$_googleMapsApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] != null && data['result']['geometry'] != null) {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      debugPrint('Place details error: $e');
    }
    return null;
  }

  Future<void> _selectPlace(PlacePrediction place) async {
    setState(() {
      _showSearchResults = false;
      _isLoadingRoute = true;
    });

    final latLng = await _getPlaceDetails(place.placeId);

    if (latLng != null) {
      if (_activeSearchField == 'start') {
        _startLatLng = latLng;
        _startController.text = place.mainText;
        _startFocusNode.unfocus();
      } else {
        _endLatLng = latLng;
        _destinationController.text = place.mainText;
        _endFocusNode.unfocus();
      }

      _updateMarkers();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 15),
      );

      if (_startLatLng != null && _endLatLng != null) {
        await _getDirections();
      }
    }

    setState(() => _isLoadingRoute = false);
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?'
            'latlng=${position.latitude},${position.longitude}'
            '&key=$_googleMapsApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final addressComponents = result['address_components'] as List;

          String? locality;
          String? subLocality;
          String? route;

          for (var component in addressComponents) {
            final types = component['types'] as List;
            if (types.contains('sublocality_level_1') || types.contains('sublocality')) {
              subLocality = component['long_name'];
            } else if (types.contains('locality')) {
              locality = component['long_name'];
            } else if (types.contains('route')) {
              route = component['long_name'];
            }
          }

          final parts = <String>[];
          if (route != null) parts.add(route);
          if (subLocality != null) parts.add(subLocality);
          if (locality != null && locality != subLocality) parts.add(locality);

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }

          return result['formatted_address'] ?? 'Selected Location';
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }

    return '${widget.currentCity} Location';
  }

  Future<void> _getDirections() async {
    if (_startLatLng == null || _endLatLng == null) return;

    setState(() => _isLoadingRoute = true);

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${_startLatLng!.latitude},${_startLatLng!.longitude}'
            '&destination=${_endLatLng!.latitude},${_endLatLng!.longitude}'
            '&mode=driving'
            '&key=$_googleMapsApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          _distance = leg['distance']['text'];
          _duration = leg['duration']['text'];

          // Decode polyline for ROAD-BASED routing
          final polylinePoints = route['overview_polyline']['points'];
          _routePoints = _decodePolyline(polylinePoints);

          // *** SOLID LINE - NO PATTERNS ***
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: _routePoints,
              color: AppColors.primaryYellow,
              width: 6,
              // EMPTY patterns = SOLID LINE
              patterns: const [],
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
          };

          _fitBounds();

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not find route: ${data['status']}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Directions error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get directions'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isLoadingRoute = false);
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
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

  void _fitBounds() {
    if (_routePoints.isEmpty || _mapController == null) return;

    double minLat = _routePoints[0].latitude;
    double maxLat = _routePoints[0].latitude;
    double minLng = _routePoints[0].longitude;
    double maxLng = _routePoints[0].longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  void _useCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _startLatLng = LatLng(position.latitude, position.longitude);
      _startController.text = 'Current Location';
      _updateMarkers();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_startLatLng!, 15),
      );

      if (_endLatLng != null) {
        await _getDirections();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get current location'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handlePublish() {
    if (_startLatLng == null || _endLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and drop-off points'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_carNameController.text.isEmpty || _carNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter car details'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final startLocation = LocationPoint(
      latitude: _startLatLng!.latitude,
      longitude: _startLatLng!.longitude,
      address: _startController.text.isNotEmpty
          ? _startController.text
          : '${widget.currentCity} Pickup',
    );

    final endLocation = LocationPoint(
      latitude: _endLatLng!.latitude,
      longitude: _endLatLng!.longitude,
      address: _destinationController.text.isNotEmpty
          ? _destinationController.text
          : '${widget.currentCity} Drop-off',
    );

    final carDetails = CarDetails(
      name: _carNameController.text,
      number: _carNumberController.text,
    );

    final fare = int.tryParse(_fareController.text);

    widget.onPublish(startLocation, endLocation, carDetails, _availableSeats, fare);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey500,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.routing_2, color: AppColors.primaryYellow, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Route in ${widget.currentCity}',
                      style: GoogleFonts.urbanist(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    Text(
                      'Step ${_currentStep + 1} of 2',
                      style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Iconsax.close_circle, color: AppColors.grey500),
                ),
              ],
            ),
          ),

          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: _currentStep >= 1
                          ? AppColors.primaryYellow
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: _currentStep == 0
                ? _buildMapRouteStep(isDark)
                : _buildCarDetailsStep(isDark),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: isDark ? AppColors.grey600 : AppColors.grey400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 1) {
                        if (_startLatLng == null || _endLatLng == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select pickup and drop-off points'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        setState(() => _currentStep++);
                      } else {
                        _handlePublish();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: AppColors.darkBackground,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentStep < 1 ? 'Continue' : 'Publish Route',
                      style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapRouteStep(bool isDark) {
    return Stack(
      children: [
        Column(
          children: [
            // Search Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Pickup field
                  _buildSearchField(
                    controller: _startController,
                    focusNode: _startFocusNode,
                    hint: 'Search pickup location...',
                    icon: Iconsax.location,
                    iconColor: AppColors.success,
                    isDark: isDark,
                    isActive: _selectingStart,
                    onTap: () {
                      setState(() {
                        _selectingStart = true;
                        _activeSearchField = 'start';
                      });
                    },
                    onChanged: (value) {
                      _activeSearchField = 'start';
                      _searchPlaces(value);
                    },
                    onClear: () {
                      _startController.clear();
                      _startLatLng = null;
                      _polylines.clear();
                      _updateMarkers();
                      setState(() {});
                    },
                    trailing: IconButton(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Iconsax.gps, color: AppColors.primaryYellow, size: 20),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Drop-off field
                  _buildSearchField(
                    controller: _destinationController,
                    focusNode: _endFocusNode,
                    hint: 'Search drop-off location...',
                    icon: Iconsax.location_tick,
                    iconColor: AppColors.error,
                    isDark: isDark,
                    isActive: !_selectingStart,
                    onTap: () {
                      setState(() {
                        _selectingStart = false;
                        _activeSearchField = 'end';
                      });
                    },
                    onChanged: (value) {
                      _activeSearchField = 'end';
                      _searchPlaces(value);
                    },
                    onClear: () {
                      _destinationController.clear();
                      _endLatLng = null;
                      _polylines.clear();
                      _updateMarkers();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tap map to select • Drag markers to adjust • Pinch to zoom',
                style: GoogleFonts.urbanist(fontSize: 11, color: AppColors.grey500),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // *** GOOGLE MAP WITH FULL GESTURE SUPPORT ***
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: widget.currentLatLng ?? const LatLng(31.4504, 73.1350),
                        zoom: 13,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                        if (isDark && _darkMapStyle != null) {
                          _mapController!.setMapStyle(_darkMapStyle);
                        }
                      },
                      onTap: _onMapTap,
                      markers: _markers,
                      polylines: _polylines,

                      // *** FULL GESTURE SUPPORT - LIKE REAL MAP ***
                      scrollGesturesEnabled: true,      // Drag to move
                      zoomGesturesEnabled: true,        // Pinch to zoom
                      rotateGesturesEnabled: true,      // Two finger rotate
                      tiltGesturesEnabled: true,        // Two finger tilt

                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                    ),

                    // Loading overlay
                    if (_isLoadingRoute)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                          ),
                        ),
                      ),

                    // Fit bounds button
                    if (_startLatLng != null && _endLatLng != null && _routePoints.isNotEmpty)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: GestureDetector(
                          onTap: _fitBounds,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Iconsax.maximize_4,
                              color: AppColors.primaryYellow,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Route info
            if (_distance != null && _duration != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryYellow.withOpacity(0.2),
                        AppColors.primaryYellow.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryYellow.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          const Icon(Iconsax.location, size: 20, color: AppColors.primaryYellow),
                          const SizedBox(width: 8),
                          Text(
                            _distance!,
                            style: GoogleFonts.urbanist(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.grey900,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: AppColors.primaryYellow.withOpacity(0.4),
                      ),
                      Row(
                        children: [
                          const Icon(Iconsax.clock, size: 20, color: AppColors.primaryYellow),
                          const SizedBox(width: 8),
                          Text(
                            _duration!,
                            style: GoogleFonts.urbanist(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.grey900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),

        // Search Results Overlay
        if (_showSearchResults)
          Positioned(
            top: 130,
            left: 20,
            right: 20,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _isSearching
                  ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.location,
                        color: AppColors.primaryYellow,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      place.mainText,
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    subtitle: Text(
                      place.secondaryText,
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectPlace(place),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required bool isActive,
    required VoidCallback onTap,
    required Function(String) onChanged,
    required VoidCallback onClear,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? iconColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: onChanged,
              onTap: onTap,
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Iconsax.close_circle, color: AppColors.grey500, size: 18),
              ),
            ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildCarDetailsStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Details',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _carNameController,
            hint: 'Car Model (e.g., Honda Civic)',
            icon: Iconsax.car,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _carNumberController,
            hint: 'License Plate (e.g., ABC-1234)',
            icon: Iconsax.card,
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          Text(
            'Available Seats',
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (i) {
              final seats = i + 1;
              final isSelected = _availableSeats == seats;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _availableSeats = seats),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryYellow
                          : (isDark ? AppColors.darkCard : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryYellow
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.user,
                          color: isSelected ? AppColors.darkBackground : AppColors.grey500,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$seats',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.darkBackground
                                : (isDark ? Colors.white : AppColors.grey900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          Text(
            'Suggested Fare (Optional)',
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _fareController,
            hint: 'Enter amount in PKR',
            icon: Iconsax.money,
            isDark: isDark,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 24),

          // Route summary
          if (_distance != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Summary',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Iconsax.location, size: 18, color: AppColors.primaryYellow),
                      const SizedBox(width: 8),
                      Text(_distance!, style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 20),
                      const Icon(Iconsax.clock, size: 18, color: AppColors.primaryYellow),
                      const SizedBox(width: 8),
                      Text(_duration!, style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    '${_startController.text} → ${_destinationController.text}',
                    style: GoogleFonts.urbanist(fontSize: 13, color: AppColors.grey500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: AppColors.primaryYellow, size: 22),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}