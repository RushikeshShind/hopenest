import 'package:flutter/material.dart';
import '../models/orphanage.dart';
import '../services/api_service.dart';

class DonationTrackingScreen extends StatefulWidget {
  final Orphanage orphanage;
  final Map<String, int> items;
  final double total;

  const DonationTrackingScreen({
    required this.orphanage,
    required this.items,
    required this.total,
    super.key,
  });

  @override
  _DonationTrackingScreenState createState() => _DonationTrackingScreenState();
}

class _DonationTrackingScreenState extends State<DonationTrackingScreen>
    with TickerProviderStateMixin {
  String status = 'pending';
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    _fadeController.forward();
    fetchStatus();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void fetchStatus() async {
    try {
      final donations = await ApiService().getDonations();
      final donation = donations.firstWhere(
        (d) => d['orphanage_id'] == widget.orphanage.id && 
               d['total'] == widget.total,
        orElse: () => {'status': 'pending'},
      );
      
      setState(() {
        status = donation['status'];
      });
      
      // Animate progress based on status
      double targetProgress = _getProgressValue(status);
      _progressController.animateTo(targetProgress);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching status: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  double _getProgressValue(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0.33;
      case 'shipped':
        return 0.66;
      case 'delivered':
        return 1.0;
      default:
        return 0.33;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF6C5CE7),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Track Donation',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildTrackingCard(),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildProgressSection(),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildDonationDetails(),
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: fetchStatus,
        backgroundColor: const Color(0xFF6C5CE7),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh Status'),
      ),
    );
  }

  Widget _buildTrackingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStatusColor(status).withOpacity(0.1),
            _getStatusColor(status).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donation to ${widget.orphanage.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${status.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressIndicator(),
          const SizedBox(height: 24),
          _buildProgressSteps(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          children: [
            LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_getStatusColor(status)),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_progressAnimation.value * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
                Text(
                  'Complete',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressSteps() {
    final steps = [
      {'title': 'Order Placed', 'status': 'pending'},
      {'title': 'In Transit', 'status': 'shipped'},
      {'title': 'Delivered', 'status': 'delivered'},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = _getProgressValue(status) > (index * 0.33);
        final isCurrent = _getProgressValue(status) > (index * 0.33) &&
                         _getProgressValue(status) <= ((index + 1) * 0.33);

        return Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? _getStatusColor(status) : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step['title']!,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  color: isCompleted ? _getStatusColor(status) : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDonationDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Donation Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.items.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${widget.total}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'pending':
      default:
        return Icons.schedule_rounded;
    }
  }
}