import 'package:flutter/material.dart';
import '../models/orphanage.dart';
import 'donation_tracking_screen.dart';
import '../services/api_service.dart';

class DonationFormScreen extends StatefulWidget {
  final Orphanage orphanage;
  final int donorId;

  const DonationFormScreen({required this.orphanage, required this.donorId, super.key});

  @override
  _DonationFormScreenState createState() => _DonationFormScreenState();
}

class _DonationFormScreenState extends State<DonationFormScreen> with SingleTickerProviderStateMixin {
  int studentCount = 0;
  Map<String, int> items = {'Clothes': 0, 'Books': 0, 'Pens': 0};
  double total = 0.0;
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void calculateTotal() {
    setState(() {
      total = (items['Clothes']! * 200 + items['Books']! * 50 + items['Pens']! * 10).toDouble();
    });
  }

  void confirmDonation() async {
    if (items.values.every((count) => count == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item to donate')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await ApiService().addDonation(widget.orphanage.id, widget.donorId, items, total);
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/donation_tracking',
          arguments: {
            'orphanage': widget.orphanage,
            'items': items,
            'total': total,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save donation: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Donate to ${widget.orphanage.name}')),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Number of Students',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        value: studentCount.toDouble(),
                        min: 0,
                        max: 50,
                        divisions: 50,
                        label: studentCount.toString(),
                        activeColor: Colors.teal,
                        onChanged: (value) {
                          setState(() {
                            studentCount = value.toInt();
                          });
                        },
                      ),
                      ...items.keys.map((item) {
                        return Row(
                          children: [
                            Expanded(child: Text(item)),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (items[item]! > 0) items[item] = items[item]! - 1;
                                  calculateTotal();
                                });
                              },
                            ),
                            Text(items[item].toString()),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  items[item] = items[item]! + 1;
                                  calculateTotal();
                                });
                              },
                            ),
                          ],
                        );
                      }).toList(),
                      const SizedBox(height: 20),
                      Text(
                        'Estimated Total: ₹$total',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: confirmDonation,
                        child: const Text('Confirm Donation'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}