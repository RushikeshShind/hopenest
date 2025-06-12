import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'edit_orphanage_screen.dart';

class OrphanageAdminHomeScreen extends StatefulWidget {
  final int userId;

  const OrphanageAdminHomeScreen({required this.userId, super.key});

  @override
  _OrphanageAdminHomeScreenState createState() => _OrphanageAdminHomeScreenState();
}

class _OrphanageAdminHomeScreenState extends State<OrphanageAdminHomeScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? orphanage;
  List<dynamic> donations = [];
  bool isLoading = false;
  String? errorMessage;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!)));
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
        errorMessage = errorMessage != null ? '$errorMessage\n$e' : 'Error fetching donations: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orphanage Admin Dashboard')),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : orphanage == null
                  ? const Center(child: Text('No orphanage found for this admin'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${orphanage!['name']} Admin!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Orphanage Details',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.teal),
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
                            ],
                          ),
                          const SizedBox(height: 10),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Name: ${orphanage!['name']}'),
                                  Text('Location: ${orphanage!['location'] ?? 'Not specified'}'),
                                  Text('Rating: ${orphanage!['rating']}'),
                                  Text('Description: ${orphanage!['description'] ?? 'Not specified'}'),
                                  Text('Contact: ${orphanage!['contact'] ?? 'Not specified'}'),
                                  Text(
                                    'Needs: ${(orphanage!['needs'] as List<dynamic>?)?.join(", ") ?? 'None'}',
                                  ),
                                  Text('Image URL: ${orphanage!['image_url'] ?? 'Not specified'}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Donations Received',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          donations.isEmpty
                              ? const Center(child: Text('No donations received yet'))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: donations.length,
                                  itemBuilder: (context, index) {
                                    final donation = donations[index];
                                    final items = donation['items'] as Map<String, dynamic>;
                                    return Card(
                                      child: ListTile(
                                        title: Text('Donation ID: ${donation['id']}'),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Donor Email: ${donation['donor_email'] ?? 'Unknown'}'),
                                            Text(
                                                'Items: ${items.entries.map((e) => '${e.key}: ${e.value}').join(", ")}'),
                                            Text('Total: ₹${donation['total']}'),
                                            Text('Status: ${donation['status']}'),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}