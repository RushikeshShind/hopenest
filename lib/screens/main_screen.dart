import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'donor_home_screen.dart';
import 'donor_donation_history_screen.dart';
import 'feedback_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int userId;
  const MainScreen({required this.userId, super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  late PageController _pageController;
  late AnimationController _navAnimationController;
  late Animation<double> _navAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _navAnimation = CurvedAnimation(
      parent: _navAnimationController,
      curve: Curves.easeInOut,
    );
    _navAnimationController.forward();
    
    _screens = [
      DonorHomeScreen(userId: widget.userId),
      DonationHistoryScreen(userId: widget.userId),
      FeedbackScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_navAnimation),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode 
                  ? Colors.grey[900]?.withOpacity(0.9)
                  : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  selectedItemColor: const Color(0xFF6C5CE7),
                  unselectedItemColor: Colors.grey.shade500,
                  selectedFontSize: 12,
                  unselectedFontSize: 11,
                  items: [
                    _buildNavItem(Icons.home_rounded, 'Home', 0),
                    _buildNavItem(Icons.history_rounded, 'History', 1),
                    _buildNavItem(Icons.feedback_rounded, 'Feedback', 2),
                    _buildNavItem(Icons.person_rounded, 'Profile', 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(_selectedIndex == index ? 8 : 4),
        decoration: BoxDecoration(
          color: _selectedIndex == index 
            ? const Color(0xFF6C5CE7).withOpacity(0.2)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 24),
      ),
      label: label,
    );
  }
}