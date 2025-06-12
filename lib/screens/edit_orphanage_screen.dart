import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditOrphanageScreen extends StatefulWidget {
  final Map<String, dynamic> orphanage;

  EditOrphanageScreen({required this.orphanage});

  @override
  _EditOrphanageScreenState createState() => _EditOrphanageScreenState();
}

class _EditOrphanageScreenState extends State<EditOrphanageScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController needsController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.orphanage['name'];
    locationController.text = widget.orphanage['location'] ?? '';
    contactController.text = widget.orphanage['contact'] ?? '';
    descriptionController.text = widget.orphanage['description'] ?? '';
    needsController.text = (widget.orphanage['needs'] as List<dynamic>?)?.join(', ') ?? '';
    imageUrlController.text = widget.orphanage['image_url'] ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    contactController.dispose();
    descriptionController.dispose();
    needsController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  void _updateOrphanage() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final needs = needsController.text.isNotEmpty
          ? needsController.text.split(',').map((e) => e.trim()).toList().cast<String>()
          : <String>[];
      await ApiService().updateOrphanage(
        orphanageId: widget.orphanage['id'],
        name: nameController.text,
        location: locationController.text,
        contact: contactController.text,
        description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
        needs: needs,
        imageUrl: imageUrlController.text.isNotEmpty ? imageUrlController.text : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Orphanage updated successfully')),
      );
      Navigator.pop(context, true); // Return true to indicate update success
    } catch (e) {
      setState(() {
        errorMessage = 'Error updating orphanage: $e';
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
      appBar: AppBar(title: Text('Edit Orphanage')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Orphanage Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: InputDecoration(
                  labelText: 'Contact Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              TextField(
                controller: needsController,
                decoration: InputDecoration(
                  labelText: 'Needs (comma-separated, e.g., Food, Clothes)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Image URL (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: 20),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(errorMessage!, style: TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: isLoading ? null : _updateOrphanage,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Update Orphanage'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}