import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Core/Theme/App_theme.dart';
import '../Chat/Chat_Screen.dart';

/// ============================================
/// RIDE REQUESTS SCREEN (DRIVER)
/// NO AUTO-REFRESH - Manual refresh only
/// ============================================

class RideRequestsScreen extends StatefulWidget {
  final String rideId;
  final String driverId;

  const RideRequestsScreen({
    super.key,
    required this.rideId,
    required this.driverId,
  });

  @override
  State<RideRequestsScreen> createState() => _RideRequestsScreenState();
}

class _RideRequestsScreenState extends State<RideRequestsScreen> {
  // Local state - no streams!
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load once on init - NO AUTO-REFRESH
    _loadRequests();
  }

  /// ONE-TIME load - no stream, no auto-refresh
  Future<void> _loadRequests() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use .get() NOT .snapshots() - this is the key difference!
      final snapshot = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('rideId', isEqualTo: widget.rideId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get(); // <-- .get() = one-time fetch, NOT .snapshots()

      if (!mounted) return;

      final requests = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Manual refresh - only called when user taps button
  Future<void> _manualRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('rideId', isEqualTo: widget.rideId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      if (!mounted) return;

      final requests = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      setState(() {
        _requests = requests;
        _isRefreshing = false;
      });

      Get.snackbar(
        'Refreshed',
        'Found ${requests.length} pending request${requests.length == 1 ? '' : 's'}',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      Get.snackbar(
        'Error',
        'Failed to refresh',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// Accept request
  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
        barrierDismissible: false,
      );

      final batch = FirebaseFirestore.instance.batch();

      // Update request status
      batch.update(
        FirebaseFirestore.instance.collection('ride_requests').doc(request['id']),
        {'status': 'accepted'},
      );

      // Update ride with passenger info
      batch.update(
        FirebaseFirestore.instance.collection('rides').doc(widget.rideId),
        {
          'status': 'accepted',
          'passengerId': request['passengerId'],
          'passengerName': request['name'],
          'acceptedFare': request['offeredFare'],
        },
      );

      // Reject other pending requests
      final otherRequests = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('rideId', isEqualTo: widget.rideId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in otherRequests.docs) {
        if (doc.id != request['id']) {
          batch.update(doc.reference, {'status': 'rejected'});
        }
      }

      await batch.commit();

      Get.back(); // Close loading
      Get.back(); // Go back

      Get.snackbar(
        'Accepted',
        '${request['name']} has been accepted',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Failed to accept: $e',
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  /// Reject request
  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    try {
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(request['id'])
          .update({'status': 'rejected'});

      // Remove from LOCAL list only - no stream to trigger rebuild
      setState(() {
        _requests.removeWhere((r) => r['id'] == request['id']);
      });

      Get.snackbar(
        'Declined',
        '${request['name']}\'s request declined',
        backgroundColor: AppColors.grey600,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline',
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Iconsax.arrow_left,
              color: isDark ? Colors.white : AppColors.grey900),
        ),
        title: Text(
          'Ride Requests',
          style: GoogleFonts.urbanist(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
        centerTitle: true,
        actions: [
          // ========== REFRESH BUTTON ==========
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _isRefreshing ? null : _manualRefresh,
              tooltip: 'Refresh',
              icon: _isRefreshing
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryYellow,
                ),
              )
                  : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.refresh,
                  color: AppColors.primaryYellow,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    // Loading state
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryYellow),
            const SizedBox(height: 16),
            Text('Loading requests...',
                style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500)),
          ],
        ),
      );
    }

    // Error state
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2, size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load',
                style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.grey900)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRequests,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: AppColors.darkBackground,
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.message_notif,
                  size: 50, color: AppColors.primaryYellow),
            ),
            const SizedBox(height: 24),
            Text(
              'No Pending Requests',
              style: GoogleFonts.urbanist(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap refresh to check for new requests',
              style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _manualRefresh,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: AppColors.darkBackground,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    // Requests list - NO StreamBuilder!
    return RefreshIndicator(
      onRefresh: _manualRefresh,
      color: AppColors.primaryYellow,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _RequestCard(
            request: request,
            onAccept: () => _acceptRequest(request),
            onReject: () => _rejectRequest(request),
            onChat: () => Get.to(
                  () => ChatScreen(
                userName: request['name'] ?? 'Passenger',
                recipientId: request['passengerId'],
                isDriver: true,
              ),
              transition: Transition.rightToLeftWithFade,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: (index * 80).ms)
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

/// ============================================
/// REQUEST CARD WIDGET
/// ============================================

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onChat;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    (request['name'] as String?)?.substring(0, 1).toUpperCase() ??
                        'P',
                    style: GoogleFonts.urbanist(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBackground,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['name'] ?? 'Passenger',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Iconsax.star1,
                            color: AppColors.primaryYellow, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${request['rating'] ?? 4.5}',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey500,
                          ),
                        ),
                        if (request['distance'] != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              request['distance'],
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Chat button
              GestureDetector(
                onTap: onChat,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.message,
                      color: AppColors.primaryYellow, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Route info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Pickup
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        request['pickup'] ?? 'Pickup location',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : AppColors.grey700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Dots
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    children: List.generate(
                      2,
                          (_) => Container(
                        width: 2,
                        height: 6,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: AppColors.grey500.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                // Dropoff
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        request['dropoff'] ?? 'Drop-off location',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : AppColors.grey700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Time ago
          if (request['createdAt'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Iconsax.clock, size: 14, color: AppColors.grey500),
                  const SizedBox(width: 6),
                  Text(
                    _timeAgo(request['createdAt']),
                    style: GoogleFonts.urbanist(
                        fontSize: 12, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
          // Fare + Buttons
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Offered Fare',
                      style: GoogleFonts.urbanist(
                          fontSize: 12, color: AppColors.grey500)),
                  Text(
                    'Rs. ${request['offeredFare'] ?? 0}',
                    style: GoogleFonts.urbanist(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Decline',
                    style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Accept',
                    style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime time;
    if (timestamp is Timestamp) {
      time = timestamp.toDate();
    } else if (timestamp is DateTime) {
      time = timestamp;
    } else {
      return '';
    }

    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}