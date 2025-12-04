import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Core/Theme/App_theme.dart';

/// ============================================
/// REQUEST COUNT BADGE
/// Shows count WITHOUT causing parent rebuilds
/// Use this instead of StreamBuilder in parent widget
/// ============================================

class RequestCountBadge extends StatefulWidget {
  final String? rideId;
  final bool showZero;

  const RequestCountBadge({
    super.key,
    required this.rideId,
    this.showZero = false,
  });

  @override
  State<RequestCountBadge> createState() => _RequestCountBadgeState();
}

class _RequestCountBadgeState extends State<RequestCountBadge> {
  int _count = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  @override
  void didUpdateWidget(RequestCountBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rideId != widget.rideId) {
      _loadCount();
    }
  }

  /// Load count once - no stream
  Future<void> _loadCount() async {
    if (widget.rideId == null) {
      setState(() {
        _count = 0;
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('rideId', isEqualTo: widget.rideId)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      if (mounted) {
        setState(() {
          _count = snapshot.count ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _count = 0;
          _isLoading = false;
        });
      }
    }
  }

  /// Call this method to refresh the count manually
  void refresh() {
    _loadCount();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primaryYellow,
        ),
      );
    }

    if (_count == 0 && !widget.showZero) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _count > 0 ? AppColors.primaryYellow : AppColors.grey500,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$_count',
        style: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.darkBackground,
        ),
      ),
    );
  }
}

/// ============================================
/// USAGE EXAMPLE IN DRIVER HOME SCREEN:
/// ============================================
///
/// // Instead of StreamBuilder, use:
///
/// final _badgeKey = GlobalKey<_RequestCountBadgeState>();
///
/// // In build:
/// RequestCountBadge(
///   key: _badgeKey,
///   rideId: _activeRide?.id,
/// )
///
/// // To refresh manually:
/// _badgeKey.currentState?.refresh();
///
/// ============================================


/// ============================================
/// ALTERNATIVE: Simple Request Count Widget
/// That loads on tap (for use in buttons)
/// ============================================

class RequestsButton extends StatefulWidget {
  final String? rideId;
  final VoidCallback onTap;

  const RequestsButton({
    super.key,
    required this.rideId,
    required this.onTap,
  });

  @override
  State<RequestsButton> createState() => _RequestsButtonState();
}

class _RequestsButtonState extends State<RequestsButton> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  @override
  void didUpdateWidget(RequestsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rideId != widget.rideId) {
      _loadCount();
    }
  }

  Future<void> _loadCount() async {
    if (widget.rideId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('rideId', isEqualTo: widget.rideId)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      if (mounted) {
        setState(() => _count = snapshot.count ?? 0);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _loadCount(); // Refresh count when tapped
        widget.onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _count > 0
                ? AppColors.primaryYellow
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Requests',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _count > 0 ? AppColors.primaryYellow : AppColors.grey500,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_count',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBackground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}