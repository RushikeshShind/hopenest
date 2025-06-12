import 'package:flutter/material.dart';
import '../models/orphanage.dart';
import '../services/api_service.dart';
import 'dart:convert';

class DonationTrackingScreen extends StatefulWidget {
  final Orphanage orphanage;
  final Map<String, int> items;
  final double total;

  DonationTrackingScreen({
    required this.orphanage,
    required this.items,
    required this.total,
  });

  @override
  _DonationTrackingScreenState createState() => _DonationTrackingScreenState();
}

class _DonationTrackingScreenState extends State<DonationTrackingScreen> {
  String status = 'pending';

  @override
  void initState() {
    super.initState();
    fetchStatus();
  }

  void fetchStatus() async {
    try {
      final donations = await ApiService().getDonations();
      final donation = donations.firstWhere(
        (d) => d['orphanage_id'] == widget.orphanage.id && d['total'] == widget.total,
        orElse: () => {'status': 'pending'},
      );
      setState(() {
        status = donation['status'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = status == 'pending' ? 0.3 : status == 'shipped' ? 0.6 : 1.0;
    return Scaffold(
      appBar: AppBar(title: Text('Track Donation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Donation to ${widget.orphanage.name}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Items:'),
            ...widget.items.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
            SizedBox(height: 16),
            Text('Total: ₹${widget.total}'),
            SizedBox(height: 16),
            Text('Status: $status'),
            SizedBox(height: 20),
            LinearProgressIndicator(value: progress),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchStatus,
              child: Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}