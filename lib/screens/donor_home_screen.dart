import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import '../models/orphanage.dart';

class DonorHomeScreen extends StatefulWidget {
  final int userId;
  const DonorHomeScreen({required this.userId, super.key});

  @override
  _DonorHomeScreenState createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> with SingleTickerProviderStateMixin {
  List<dynamic> orphanages = [];
  bool isLoading = false;
  String? errorMessage;
  final TextEditingController locationController = TextEditingController();
  late AnimationController _controller;
  late Animation<Offset> _animation;
  String? selectedCity = 'All';
  final List<Map<String, dynamic>> cities = [
    {'name': 'All', 'icon': Icons.language},
    {'name': 'Mumbai', 'icon': Icons.apartment},
    {'name': 'Pune', 'icon': Icons.business},
    {'name': 'Nashik', 'icon': Icons.local_florist},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    searchOrphanages();
  }

  @override
  void dispose() {
    _controller.dispose();
    locationController.dispose();
    super.dispose();
  }

  void searchOrphanages() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await ApiService().getOrphanages(locationController.text);
      setState(() {
        orphanages = data;
        _controller.reset();
        _controller.forward();
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching orphanages: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
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
        title: const Text('HopeNest - Find Orphanages'),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: searchOrphanages,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Search by Location',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      locationController.clear();
                      setState(() {
                        selectedCity = 'All';
                      });
                      searchOrphanages();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onSubmitted: (value) {
                  setState(() {
                    selectedCity = null;
                  });
                  searchOrphanages();
                },
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: cities.map((city) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        avatar: Icon(
                          city['icon'],
                          color: selectedCity == city['name'] ? Colors.white : Colors.teal,
                        ),
                        label: Text(city['name']),
                        selected: selectedCity == city['name'],
                        selectedColor: Colors.teal,
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: selectedCity == city['name'] ? Colors.white : Colors.black,
                        ),
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              selectedCity = city['name'];
                              locationController.text = city['name'] == 'All' ? '' : city['name'];
                            });
                            searchOrphanages();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? ListView.builder(
                        itemCount: 3,
                        itemBuilder: (context, index) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: Container(width: 60, height: 60, color: Colors.white),
                              title: Container(width: double.infinity, height: 16, color: Colors.white),
                              subtitle: Container(width: double.infinity, height: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      )
                    : errorMessage != null
                        ? Center(child: Text(errorMessage!))
                        : orphanages.isEmpty
                            ? const Center(child: Text('No orphanages found'))
                            : SlideTransition(
                                position: _animation,
                                child: ListView.builder(
                                  itemCount: orphanages.length,
                                  itemBuilder: (context, index) {
                                    final orphanage = orphanages[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/donation_form',
                                          arguments: {
                                            'orphanage': Orphanage(
                                              id: orphanage['id'],
                                              name: orphanage['name'],
                                              location: orphanage['location'] ?? '',
                                              rating: orphanage['rating']?.toDouble() ?? 0.0,
                                              needs: List<String>.from(orphanage['needs'] ?? []),
                                              description: orphanage['description'] ?? '',
                                              imageUrl: orphanage['image_url'] ?? '',
                                              contact: orphanage['contact'] ?? '',
                                            ),
                                            'donorId': widget.userId,
                                          },
                                        );
                                      },
                                      child: Card(
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Row(
                                            children: [
                                              Hero(
                                                tag: 'image_${orphanage['id']}',
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: SizedBox(
                                                    width: 80,
                                                    height: 80,
                                                    child: Image.network(
                                                      orphanage['image_url'] ??
                                                          'https://via.placeholder.com/150',
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return const Center(
                                                            child: CircularProgressIndicator());
                                                      },
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: Colors.grey[200],
                                                          child: const Center(
                                                              child: Icon(Icons.error, color: Colors.red)),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      orphanage['name'] ?? 'Unknown',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Location: ${orphanage['location'] ?? 'Not specified'}',
                                                      style: TextStyle(color: Colors.grey[600]),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Needs: ${(orphanage['needs'] as List<dynamic>?)?.join(", ") ?? 'None'}',
                                                      style: TextStyle(color: Colors.grey[600]),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}