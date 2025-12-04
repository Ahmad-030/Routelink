import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../Models/Ride_model.dart';
import '../../Services/Firebase Auth.dart';

/// ============================================
/// PASSENGER HISTORY SCREEN
/// Shows completed rides history
/// ============================================

class PassengerHistoryScreen extends StatefulWidget {
  const PassengerHistoryScreen({super.key});

  @override
  State<PassengerHistoryScreen> createState() => _PassengerHistoryScreenState();
}

class _PassengerHistoryScreenState extends State<PassengerHistoryScreen> {
  List<RideModel> _completedRides = [];
  bool _isLoading = true;
  StreamSubscription? _ridesSubscription;

  // Stats
  int _totalRides = 0;
  double _totalDistance = 0;
  int _totalSpent = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _ridesSubscription?.cancel();
    super.dispose();
  }

  void _loadHistory() {
    final userId = AuthService.to.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _ridesSubscription = FirebaseFirestore.instance
        .collection('rides')
        .where('passengerId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final rides = snapshot.docs.map((doc) {
        return RideModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();

      // Calculate stats
      double totalDist = 0;
      int totalMoney = 0;
      for (var ride in rides) {
        totalDist += ride.distance ?? 0;
        totalMoney += ride.acceptedFare ?? ride.suggestedFare ?? 0;
      }

      setState(() {
        _completedRides = rides;
        _totalRides = rides.length;
        _totalDistance = totalDist;
        _totalSpent = totalMoney;
        _isLoading = false;
      });
    }, onError: (e) {
      debugPrint('History stream error: $e');
      setState(() => _isLoading = false);
    });
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
          'Ride History',
          style: GoogleFonts.urbanist(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
        ),
      )
          : Column(
        children: [
          // Stats card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryYellow.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    icon: Iconsax.car,
                    value: '$_totalRides',
                    label: 'Rides',
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppColors.darkBackground.withOpacity(0.2),
                  ),
                  _buildStatItem(
                    icon: Iconsax.location,
                    value: '${_totalDistance.toStringAsFixed(1)} km',
                    label: 'Distance',
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppColors.darkBackground.withOpacity(0.2),
                  ),
                  _buildStatItem(
                    icon: Iconsax.money,
                    value: 'Rs.$_totalSpent',
                    label: 'Spent',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
          ),

          // Rides list
          Expanded(
            child: _completedRides.isEmpty
                ? _buildEmptyState(isDark)
                : RefreshIndicator(
              color: AppColors.primaryYellow,
              onRefresh: () async => _loadHistory(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _completedRides.length,
                itemBuilder: (context, index) {
                  final ride = _completedRides[index];
                  return _HistoryCard(ride: ride)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                      .slideX(begin: 0.1, end: 0);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.darkBackground, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkBackground,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 12,
            color: AppColors.darkBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
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
            child: const Icon(
              Iconsax.car,
              size: 48,
              color: AppColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Rides Yet',
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed rides will appear here',
            style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final RideModel ride;

  const _HistoryCard({required this.ride});

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
              // Driver avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    (ride.driverName ?? 'D').substring(0, 1).toUpperCase(),
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
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
                      ride.driverName ?? 'Driver',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    Text(
                      _formatDate(ride.completedAt ?? ride.createdAt),
                      style: GoogleFonts.urbanist(fontSize: 13, color: AppColors.grey500),
                    ),
                  ],
                ),
              ),

              // Completed badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.tick_circle, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Completed',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Route
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
                        ride.startLocation.address,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
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
                        ride.endLocation.address,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
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

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                icon: Iconsax.location,
                value: '${ride.distance?.toStringAsFixed(1) ?? '0'} km',
                isDark: isDark,
              ),
              _buildInfoChip(
                icon: Iconsax.clock,
                value: '${ride.estimatedDuration ?? 0} min',
                isDark: isDark,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Rs. ${ride.acceptedFare ?? ride.suggestedFare ?? 0}',
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBackground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey500),
        const SizedBox(width: 6),
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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}