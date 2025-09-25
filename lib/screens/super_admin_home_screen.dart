import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SuperAdminHomeScreen extends StatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  _SuperAdminHomeScreenState createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends State<SuperAdminHomeScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> donations = [];
  List<dynamic> users = [];
  String? fetchDonationsError;
  String? fetchUsersError;
  bool isLoading = false;
  int selectedTabIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController, 
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    fetchDonations();
    fetchUsers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void fetchDonations() async {
    setState(() {
      isLoading = true;
      fetchDonationsError = null;
    });
    try {
      final data = await ApiService().getDonations();
      setState(() {
        donations = data;
      });
    } catch (e) {
      setState(() {
        fetchDonationsError = 'Error fetching donations: $e';
      });
      _showErrorSnackBar(fetchDonationsError!);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void fetchUsers() async {
    setState(() {
      isLoading = true;
      fetchUsersError = null;
    });
    try {
      final data = await ApiService().getUsers();
      setState(() {
        users = data;
      });
    } catch (e) {
      setState(() {
        fetchUsersError = 'Error fetching users: $e';
      });
      _showErrorSnackBar(fetchUsersError!);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateDonationStatus(int donationId, String newStatus) async {
    try {
      await ApiService().updateDonationStatus(donationId, newStatus);
      _showSuccessSnackBar('Donation status updated successfully');
      fetchDonations();
    } catch (e) {
      _showErrorSnackBar('Error updating donation status: $e');
    }
  }

  void deleteUser(int userId) async {
    bool? confirm = await _showDeleteConfirmation();

    if (confirm == true) {
      try {
        await ApiService().deleteUser(userId);
        _showSuccessSnackBar('User deleted successfully');
        fetchUsers();
      } catch (e) {
        _showErrorSnackBar('Error deleting user: $e');
      }
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[600]),
            const SizedBox(width: 12),
            const Text('Confirm Delete'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final items = donation['items'] is String
        ? Map<String, dynamic>.from(jsonDecode(donation['items']))
        : donation['items'] as Map<String, dynamic>;
    
    final statusColor = _getStatusColor(donation['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                Expanded(
                  child: Text(
                    'Orphanage ID: ${donation['orphanage_id']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    donation['status'].toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.currency_rupee, color: Colors.green[600], size: 20),
                Text(
                  '${donation['total']}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Items:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: items.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: donation['status'],
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                  style: TextStyle(color: Colors.grey[800], fontSize: 14),
                  items: ['pending', 'shipped', 'delivered']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      updateDonationStatus(donation['id'], newStatus);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[300]!, Colors.purple[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['email'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user['role'].toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => deleteUser(user['id']),
              icon: const Icon(Icons.delete_outline),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  title: 'Total Donations',
                  value: donations.length.toString(),
                  icon: Icons.volunteer_activism,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatsCard(
                  title: 'Total Users',
                  value: users.length.toString(),
                  icon: Icons.people,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedTabIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: selectedTabIndex == 0
                          ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
                          : null,
                    ),
                    child: Text(
                      'Donations',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selectedTabIndex == 0 ? Colors.blue : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedTabIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: selectedTabIndex == 1
                          ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
                          : null,
                    ),
                    child: Text(
                      'Users',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selectedTabIndex == 1 ? Colors.purple : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: selectedTabIndex == 0 ? _buildDonationsList() : _buildUsersList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  title: 'Total Donations',
                  value: donations.length.toString(),
                  icon: Icons.volunteer_activism,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildStatsCard(
                  title: 'Total Users',
                  value: users.length.toString(),
                  icon: Icons.people,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildStatsCard(
                  title: 'Pending Donations',
                  value: donations.where((d) => d['status'] == 'pending').length.toString(),
                  icon: Icons.pending,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildStatsCard(
                  title: 'Delivered',
                  value: donations.where((d) => d['status'] == 'delivered').length.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Donations',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: _buildDonationsList()),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Users',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: _buildUsersList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationsList() {
    if (donations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No donations available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: donations.length,
      itemBuilder: (context, index) => _buildDonationCard(donations[index]),
    );
  }

  Widget _buildUsersList() {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No users available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) => _buildUserCard(users[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Super Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              fetchDonations();
              fetchUsers();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : isDesktop
                ? _buildDesktopView()
                : _buildMobileView(),
      ),
    );
  }
}