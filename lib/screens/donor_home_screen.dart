import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../models/orphanage.dart';

class DonorHomeScreen extends StatefulWidget {
  final int userId;
  const DonorHomeScreen({required this.userId, super.key});

  @override
  _DonorHomeScreenState createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> 
    with TickerProviderStateMixin {
  List<dynamic> orphanages = [];
  List<dynamic> filteredOrphanages = [];
  bool isLoading = false;
  String? errorMessage;
  final TextEditingController searchController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  String? selectedCity = 'All';
  
  final List<Map<String, dynamic>> cities = [
    {'name': 'All', 'icon': Icons.explore_rounded, 'color': const Color(0xFF6C5CE7)},
    {'name': 'Mumbai', 'icon': Icons.apartment_rounded, 'color': const Color(0xFF74B9FF)},
    {'name': 'Pune', 'icon': Icons.business_rounded, 'color': const Color(0xFF00B894)},
    {'name': 'Nashik', 'icon': Icons.local_florist_rounded, 'color': const Color(0xFF55A3FF)},
    {'name': 'Delhi', 'icon': Icons.location_city_rounded, 'color': const Color(0xFFFF7675)},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    searchOrphanages();
    
    searchController.addListener(_onSearchChanged);
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredOrphanages = orphanages;
      } else {
        filteredOrphanages = orphanages.where((orphanage) {
          final name = (orphanage['name'] ?? '').toLowerCase();
          final location = (orphanage['location'] ?? '').toLowerCase();
          final needs = (orphanage['needs'] as List<dynamic>?)
              ?.join(' ')
              .toLowerCase() ?? '';
          
          return name.contains(query) || 
                 location.contains(query) || 
                 needs.contains(query);
        }).toList();
      }
    });
  }

  void searchOrphanages() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final locationQuery = selectedCity == 'All' ? '' : selectedCity!;
      final data = await ApiService().getOrphanages(locationQuery);
      
      setState(() {
        orphanages = data;
        filteredOrphanages = data;
      });
      
      // Animate cards in
      _fadeController.forward();
      _slideController.forward();
      
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching orphanages: $e';
      });
      _showErrorSnackBar(errorMessage!);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onCitySelected(String cityName) {
    HapticFeedback.lightImpact();
    setState(() {
      selectedCity = cityName;
      searchController.clear();
    });
    
    _scaleController.forward().then((_) => _scaleController.reverse());
    
    // Reset animations for new data
    _fadeController.reset();
    _slideController.reset();
    
    searchOrphanages();
  }

  void _onOrphanageTap(Map<String, dynamic> orphanage) {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(
      context,
      '/donation_form',
      arguments: {
        'orphanage': Orphanage(
          id: orphanage['id'],
          name: orphanage['name'],
          location: orphanage['location'] ?? '',
          rating: (orphanage['rating'] as num?)?.toDouble() ?? 0.0,
          needs: List<String>.from(orphanage['needs'] ?? []),
          description: orphanage['description'] ?? '',
          imageUrl: orphanage['image_url'] ?? '',
          contact: orphanage['contact'] ?? '',
        ),
        'donorId': widget.userId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isTablet),
          SliverPadding(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSearchSection(isTablet),
                const SizedBox(height: 20),
                _buildCityFilter(isTablet),
                const SizedBox(height: 24),
                _buildStatsCard(isTablet),
                const SizedBox(height: 24),
              ]),
            ),
          ),
          _buildOrphanagesList(isTablet),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar(bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 200 : 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6C5CE7),
                Color(0xFF74B9FF),
                Color(0xFF00B894),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated background elements
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: isTablet ? 40 : 30,
                left: isTablet ? 32 : 24,
                right: isTablet ? 32 : 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HopeNest',
                      style: TextStyle(
                        fontSize: isTablet ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Find & Support Orphanages',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: () {
              _fadeController.reset();
              _slideController.reset();
              searchOrphanages();
            },
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search orphanages, locations, needs...',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Color(0xFF6C5CE7),
            ),
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      selectedCity = 'All';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: isTablet ? 20 : 16,
          ),
        ),
        style: TextStyle(fontSize: isTablet ? 16 : 14),
      ),
    );
  }

  Widget _buildCityFilter(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Locations',
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: isTablet ? 60 : 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
              final isSelected = selectedCity == city['name'];
              
              return AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isSelected ? (1.0 + _scaleAnimation.value * 0.1) : 1.0,
                    child: GestureDetector(
                      onTap: () => _onCitySelected(city['name']),
                      child: Container(
                        margin: EdgeInsets.only(
                          right: 12,
                          left: index == 0 ? 0 : 0,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 20 : 16,
                          vertical: isTablet ? 12 : 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [city['color'], city['color'].withOpacity(0.7)],
                                )
                              : null,
                          color: isSelected ? null : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.transparent 
                                : Colors.grey.shade300,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: city['color'].withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              city['icon'],
                              size: isTablet ? 20 : 18,
                              color: isSelected ? Colors.white : city['color'],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              city['name'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                                fontWeight: isSelected 
                                    ? FontWeight.w600 
                                    : FontWeight.w500,
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF74B9FF),
            Color(0xFF0984E3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF74B9FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${filteredOrphanages.length}',
                  style: TextStyle(
                    fontSize: isTablet ? 36 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Orphanages Found',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.home_work_rounded,
              size: isTablet ? 40 : 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrphanagesList(bool isTablet) {
    if (isLoading) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildShimmerCard(isTablet),
            childCount: 3,
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return SliverFillRemaining(
        child: _buildErrorState(isTablet),
      );
    }

    if (filteredOrphanages.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(isTablet),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildOrphanageCard(
                  filteredOrphanages[index],
                  index,
                  isTablet,
                ),
              ),
            );
          },
          childCount: filteredOrphanages.length,
        ),
      ),
    );
  }

  Widget _buildOrphanageCard(Map<String, dynamic> orphanage, int index, bool isTablet) {
    final needs = orphanage['needs'] as List<dynamic>? ?? [];
    
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _onOrphanageTap(orphanage),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'image_${orphanage['id']}',
                        child: Container(
                          width: isTablet ? 100 : 80,
                          height: isTablet ? 100 : 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildOrphanageImage(orphanage),
                          ),
                        ),
                      ),
                      SizedBox(width: isTablet ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orphanage['name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: isTablet ? 18 : 16,
                                  color: const Color(0xFF6C5CE7),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    orphanage['location'] ?? 'Not specified',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: isTablet ? 16 : 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (orphanage['rating'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: isTablet ? 18 : 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${orphanage['rating']?.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: isTablet ? 16 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: const Color(0xFF6C5CE7),
                          size: isTablet ? 20 : 18,
                        ),
                      ),
                    ],
                  ),
                  if (needs.isNotEmpty) ...[
                    SizedBox(height: isTablet ? 16 : 12),
                    Text(
                      'Current Needs:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: needs.take(3).map((need) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 12 : 10,
                            vertical: isTablet ? 6 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF74B9FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF74B9FF).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            need.toString(),
                            style: TextStyle(
                              color: const Color(0xFF74B9FF),
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrphanageImage(Map<String, dynamic> orphanage) {
    return orphanage['image_url'] != null && orphanage['image_url'].isNotEmpty
        ? Image.network(
            orphanage['image_url'],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.image_not_supported_rounded,
                  color: Colors.grey.shade400,
                ),
              );
            },
          )
        : Container(
            color: Colors.grey.shade200,
            child: Icon(
              Icons.home_work_rounded,
              color: Colors.grey.shade400,
              size: 32,
            ),
          );
  }

  Widget _buildShimmerCard(bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      height: isTablet ? 160 : 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: isTablet ? 80 : 64,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            Text(
              'No orphanages found',
              style: TextStyle(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'Try adjusting your search or location filter',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: isTablet ? 80 : 64,
                color: Colors.red.shade400,
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              errorMessage ?? 'Please try again',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 32 : 24),
            ElevatedButton.icon(
              onPressed: searchOrphanages,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24,
                  vertical: isTablet ? 16 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        searchController.clear();
        setState(() {
          selectedCity = 'All';
          filteredOrphanages = orphanages;
        });
      },
      backgroundColor: const Color(0xFF6C5CE7),
      icon: const Icon(Icons.clear_all_rounded),
      label: const Text('Clear Filters'),
    );
  }
}