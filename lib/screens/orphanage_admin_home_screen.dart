import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'edit_orphanage_screen.dart';

class OrphanageAdminHomeScreen extends StatefulWidget {
  final int userId;

  const OrphanageAdminHomeScreen({required this.userId, super.key});

  @override
  _OrphanageAdminHomeScreenState createState() => _OrphanageAdminHomeScreenState();
}

class _OrphanageAdminHomeScreenState extends State<OrphanageAdminHomeScreen> 
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? orphanage;
  List<dynamic> donations = [];
  bool isLoading = false;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    fetchOrphanageDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void fetchOrphanageDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await ApiService().getOrphanageForAdmin(widget.userId);
      setState(() {
        orphanage = data;
      });
      fetchDonations();
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching orphanage: $e';
      });
      _showErrorSnackBar(errorMessage!);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void fetchDonations() async {
    try {
      if (orphanage != null) {
        final data = await ApiService().getDonations(orphanageId: orphanage!['id']);
        setState(() {
          donations = data;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = errorMessage != null 
            ? '$errorMessage\n$e' 
            : 'Error fetching donations: $e';
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logout,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from your admin dashboard?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    Navigator.of(context).pop(); // Close dialog
    
    // Clear any stored user data or tokens here
    // Example: SharedPreferences, secure storage, etc.
    
    // Show logout success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Successfully logged out'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Navigate to login screen (replace with your actual login route)
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // Replace with your login route
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        shadowColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.logout,
                color: Colors.red.shade600,
                size: 22,
              ),
              onPressed: _showLogoutDialog,
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              fetchOrphanageDetails();
            },
            color: Colors.teal.shade600,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingState();
    }
    
    if (orphanage == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildOrphanageDetailsCard(),
          const SizedBox(height: 24),
          _buildDonationsSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.teal.shade600,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your dashboard...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Orphanage Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No orphanage is associated with this admin account',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade200.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back! 👋',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            orphanage!['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Admin Dashboard',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Donations',
            '${donations.length}',
            Icons.volunteer_activism,
            Colors.blue.shade400,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Amount',
            '₹${donations.fold<int>(0, (int sum, donation) => sum + ((donation['total'] as num?)?.toInt() ?? 0))}',
            Icons.account_balance_wallet,
            Colors.green.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrphanageDetailsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orphanage Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit, color: Colors.teal.shade600, size: 20),
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/edit_orphanage',
                        arguments: orphanage,
                      );
                      if (result == true && mounted) {
                        fetchOrphanageDetails();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailRow(Icons.home, 'Name', orphanage!['name']),
                _buildDetailRow(Icons.location_on, 'Location', 
                    orphanage!['location'] ?? 'Not specified'),
                _buildDetailRow(Icons.star, 'Rating', '${orphanage!['rating']}'),
                _buildDetailRow(Icons.description, 'Description', 
                    orphanage!['description'] ?? 'Not specified'),
                _buildDetailRow(Icons.phone, 'Contact', 
                    orphanage!['contact'] ?? 'Not specified'),
                _buildDetailRow(Icons.list, 'Needs', 
                    (orphanage!['needs'] as List<dynamic>?)?.join(", ") ?? 'None'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Donations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        donations.isEmpty ? _buildNoDonations() : _buildDonationsList(),
      ],
    );
  }

  Widget _buildNoDonations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No Donations Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Donations will appear here once received',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationsList() {
    return Column(
      children: donations.map((donation) => _buildDonationCard(donation)).toList(),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final items = donation['items'] as Map<String, dynamic>;
    final status = donation['status']?.toString().toLowerCase() ?? 'unknown';
    
    Color statusColor = Colors.grey;
    if (status == 'completed') statusColor = Colors.green;
    if (status == 'pending') statusColor = Colors.orange;
    if (status == 'cancelled') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Donation #${donation['id']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDonationDetailRow('Donor', donation['donor_email'] ?? 'Unknown'),
            _buildDonationDetailRow('Items', 
                items.entries.map((e) => '${e.key}: ${e.value}').join(", ")),
            _buildDonationDetailRow('Total Amount', '₹${donation['total']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}