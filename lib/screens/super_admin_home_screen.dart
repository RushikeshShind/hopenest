import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SuperAdminHomeScreen extends StatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  _SuperAdminHomeScreenState createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends State<SuperAdminHomeScreen> with SingleTickerProviderStateMixin {
  List<dynamic> donations = [];
  List<dynamic> users = [];
  String? fetchDonationsError;
  String? fetchUsersError;
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fetchDonationsError!)));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fetchUsersError!)));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateDonationStatus(int donationId, String newStatus) async {
    try {
      await ApiService().updateDonationStatus(donationId, newStatus);
      fetchDonations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating donation status: $e')));
    }
  }

  void deleteUser(int userId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService().deleteUser(userId);
        fetchUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Super Admin Dashboard')),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Donations',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Expanded(
                      child: donations.isEmpty
                          ? const Center(child: Text('No donations available'))
                          : ListView.builder(
                              itemCount: donations.length,
                              itemBuilder: (context, index) {
                                final donation = donations[index];
                                final items = donation['items'] is String
                                    ? Map<String, dynamic>.from(jsonDecode(donation['items']))
                                    : donation['items'] as Map<String, dynamic>;
                                return Card(
                                  child: ListTile(
                                    title: Text('Donation to Orphanage ID: ${donation['orphanage_id']}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Total: ₹${donation['total']}'),
                                        Text(
                                            'Items: ${items.entries.map((e) => '${e.key}: ${e.value}').join(", ")}'),
                                        Text('Status: ${donation['status']}'),
                                        DropdownButton<String>(
                                          value: donation['status'],
                                          items: ['pending', 'shipped', 'delivered']
                                              .map((status) =>
                                                  DropdownMenuItem(value: status, child: Text(status)))
                                              .toList(),
                                          onChanged: (newStatus) {
                                            if (newStatus != null) {
                                              updateDonationStatus(donation['id'], newStatus);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Manage Users',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Expanded(
                      child: users.isEmpty
                          ? const Center(child: Text('No users available'))
                          : ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(user['email']),
                                    subtitle: Text('Role: ${user['role']}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => deleteUser(user['id']),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}