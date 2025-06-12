import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';

class DonationHistoryScreen extends StatefulWidget {
  final int userId;

  const DonationHistoryScreen({required this.userId, super.key});

  @override
  _DonationHistoryScreenState createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  List<dynamic> donations = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDonations();
  }

  void fetchDonations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donation History'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      subtitle: Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )
            : donations.isEmpty
                ? Center(child: Text('No donations made yet'))
                : ListView.builder(
                    itemCount: donations.length,
                    itemBuilder: (context, index) {
                      final donation = donations[index];
                      final items = donation['items'] as Map<String, dynamic>;
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text('Donation ID: ${donation['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Orphanage ID: ${donation['orphanage_id']}'),
                              Text('Items: ${items.entries.map((e) => '${e.key}: ${e.value}').join(", ")}'),
                              Text('Total: ₹${donation['total']}'),
                              Text('Status: ${donation['status']}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}