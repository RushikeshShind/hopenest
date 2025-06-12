import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrphanageDetailScreen extends StatefulWidget {
  final Map<String, dynamic> orphanage;
  final int userId;

  const OrphanageDetailScreen({required this.orphanage, required this.userId, super.key});

  @override
  _OrphanageDetailScreenState createState() => _OrphanageDetailScreenState();
}

class _OrphanageDetailScreenState extends State<OrphanageDetailScreen> {
  final TextEditingController itemsController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  bool isSubmitting = false;

  void makeDonation() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Make a Donation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemsController,
                decoration: InputDecoration(
                  labelText: 'Items (e.g., Clothes: 2, Books: 5)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: totalController,
                decoration: InputDecoration(
                  labelText: 'Total Amount (₹)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  if (totalController.text.isEmpty) {
                    throw Exception('Total amount is required');
                  }
                  final total = double.tryParse(totalController.text);
                  if (total == null || total <= 0) {
                    throw Exception('Invalid total amount');
                  }

                  if (itemsController.text.isEmpty) {
                    throw Exception('Items are required');
                  }
                  final itemsList = itemsController.text.split(',').map((e) => e.trim()).toList();
                  final itemsMap = <String, int>{};
                  for (var item in itemsList) {
                    final parts = item.split(':').map((e) => e.trim()).toList();
                    if (parts.length != 2) {
                      throw Exception('Invalid item format: $item. Use "Item: Quantity" (e.g., Clothes: 2)');
                    }
                    final quantity = int.tryParse(parts[1]);
                    if (quantity == null || quantity <= 0) {
                      throw Exception('Invalid quantity for item: $item');
                    }
                    itemsMap[parts[0]] = quantity;
                  }

                  if (itemsMap.isEmpty) {
                    throw Exception('At least one valid item is required');
                  }

                  setState(() {
                    isSubmitting = true;
                  });

                  await ApiService().addDonation(widget.orphanage['id'], widget.userId, itemsMap, total);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Donation made successfully')),
                  );

                  itemsController.clear();
                  totalController.clear();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error making donation: $e')),
                  );
                } finally {
                  setState(() {
                    isSubmitting = false;
                  });
                }
              },
              child: Text('Donate'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orphanage['name'] ?? 'Orphanage Details'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            Container(
              height: 200,
              width: double.infinity,
              child: Image.network(
                widget.orphanage['image_url'] ?? 'https://via.placeholder.com/150',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Center(child: Icon(Icons.error, color: Colors.red)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.orphanage['name'] ?? 'Unknown',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Location: ${widget.orphanage['location'] ?? 'Not specified'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rating: ${widget.orphanage['rating'] ?? 0}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Description: ${widget.orphanage['description'] ?? 'Not specified'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Contact: ${widget.orphanage['contact'] ?? 'Not specified'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Needs: ${(widget.orphanage['needs'] as List<dynamic>?)?.join(", ") ?? 'None'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  isSubmitting
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: makeDonation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Center(
                            child: Text(
                              'Donate Now',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}