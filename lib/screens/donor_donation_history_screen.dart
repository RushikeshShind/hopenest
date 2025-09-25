import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DonationHistoryScreen extends StatefulWidget {
  final int userId;
  const DonationHistoryScreen({required this.userId, super.key});

  @override
  _DonationHistoryScreenState createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> 
    with SingleTickerProviderStateMixin {
  List<dynamic> donations = [];
  bool isLoading = false;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    fetchDonations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void fetchDonations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    _animationController.forward();
    
    try {
      final data = await ApiService().getDonationsByDonor(widget.userId);
      setState(() {
        donations = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching donations: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
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
                'Donation History',
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
            padding: const EdgeInsets.all(16),
            sliver: isLoading
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildShimmerCard(),
                      childCount: 3,
                    ),
                  )
                : donations.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  index * 0.1,
                                  1.0,
                                  curve: Curves.easeOutCubic,
                                ),
                              )),
                              child: _buildDonationCard(donations[index], index),
                            ),
                          ),
                          childCount: donations.length,
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: fetchDonations,
        backgroundColor: const Color(0xFF6C5CE7),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh'),
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation, int index) {
    final items = donation['items'] as Map<String, dynamic>;
    final status = donation['status'] as String;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ID: ${donation['id']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 16,
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Orphanage ID: ${donation['orphanage_id']}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.grey.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Items Donated:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: items.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.currency_rupee_rounded,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Total: ₹${donation['total']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        // Add track donation functionality
                      },
                      icon: const Icon(Icons.track_changes_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.1),
                        foregroundColor: const Color(0xFF6C5CE7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade300,
              Colors.grey.shade100,
              Colors.grey.shade300,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No donations yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your donation history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to home/donate
            },
            icon: const Icon(Icons.favorite_rounded),
            label: const Text('Make Your First Donation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}