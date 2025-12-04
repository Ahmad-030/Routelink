import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../Models/Ride_request_model.dart';
import '../../Services/Firebase Auth.dart';

/// ============================================
/// PASSENGER MY REQUESTS SCREEN
/// Shows all ride requests sent by passenger
/// ============================================

class PassengerMyRequestsScreen extends StatefulWidget {
  const PassengerMyRequestsScreen({super.key});

  @override
  State<PassengerMyRequestsScreen> createState() => _PassengerMyRequestsScreenState();
}

class _PassengerMyRequestsScreenState extends State<PassengerMyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RideRequestModel> _pendingRequests = [];
  List<RideRequestModel> _historyRequests = [];
  bool _isLoading = true;
  StreamSubscription? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  void _loadRequests() {
    final userId = AuthService.to.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _requestsSubscription = FirebaseFirestore.instance
        .collection('ride_requests')
        .where('passengerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final requests = snapshot.docs.map((doc) {
        return RideRequestModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();

      setState(() {
        _pendingRequests = requests.where((r) => r.status == 'pending').toList();
        _historyRequests = requests.where((r) => r.status != 'pending').toList();
        _isLoading = false;
      });
    }, onError: (e) {
      debugPrint('Requests stream error: $e');
      setState(() => _isLoading = false);
    });
  }

  Future<void> _cancelRequest(RideRequestModel request) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Request?',
          style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to cancel this ride request?',
          style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'No',
              style: GoogleFonts.urbanist(fontWeight: FontWeight.w600, color: AppColors.grey500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                await FirebaseFirestore.instance
                    .collection('ride_requests')
                    .doc(request.id)
                    .update({'status': 'cancelled'});
                Get.snackbar(
                  'Cancelled',
                  'Request cancelled successfully',
                  backgroundColor: AppColors.grey700,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to cancel request',
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'My Requests',
          style: GoogleFonts.urbanist(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryYellow,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primaryYellow,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBackground,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsList(_pendingRequests, isPending: true, isDark: isDark),
          _buildRequestsList(_historyRequests, isPending: false, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<RideRequestModel> requests, {required bool isPending, required bool isDark}) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPending ? Iconsax.clock : Iconsax.document,
                size: 48,
                color: AppColors.primaryYellow,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isPending ? 'No Pending Requests' : 'No Request History',
              style: GoogleFonts.urbanist(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'Your pending ride requests will appear here'
                  : 'Your past requests will appear here',
              style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryYellow,
      onRefresh: () async => _loadRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _RequestCard(
            request: request,
            onCancel: isPending ? () => _cancelRequest(request) : null,
          ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RideRequestModel request;
  final VoidCallback? onCancel;

  const _RequestCard({required this.request, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _buildStatusBadge(request.status),
              const Spacer(),
              Text(
                _formatDate(request.createdAt),
                style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Route info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground.withOpacity(0.5) : AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
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
                        request.pickupAddress,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    children: List.generate(
                      2,
                          (i) => Container(
                        width: 2,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: AppColors.grey500.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
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
                        request.dropoffAddress,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.grey900,
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
          const SizedBox(height: 14),

          // Fare info
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Offer',
                    style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500),
                  ),
                  Text(
                    'Rs. ${request.offeredFare}',
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested',
                    style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500),
                  ),
                  Text(
                    'Rs. ${request.suggestedFare ?? 0}',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.grey700,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Cancel button
              if (onCancel != null)
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Iconsax.close_circle, size: 18),
                  label: Text(
                    'Cancel',
                    style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = AppColors.info.withOpacity(0.15);
        textColor = AppColors.info;
        icon = Iconsax.clock;
        break;
      case 'accepted':
        bgColor = AppColors.success.withOpacity(0.15);
        textColor = AppColors.success;
        icon = Iconsax.tick_circle;
        break;
      case 'rejected':
        bgColor = AppColors.error.withOpacity(0.15);
        textColor = AppColors.error;
        icon = Iconsax.close_circle;
        break;
      case 'cancelled':
        bgColor = AppColors.grey500.withOpacity(0.15);
        textColor = AppColors.grey500;
        icon = Iconsax.close_circle;
        break;
      default:
        bgColor = AppColors.grey500.withOpacity(0.15);
        textColor = AppColors.grey500;
        icon = Iconsax.info_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.capitalize!,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}