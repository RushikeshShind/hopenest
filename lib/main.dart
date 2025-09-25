import 'package:flutter/material.dart';
import 'package:hopenest/models/orphanage.dart';
import 'screens/donor_home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/donor_donation_history_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/orphanage_admin_home_screen.dart';
import 'screens/super_admin_home_screen.dart';
import 'screens/edit_orphanage_screen.dart'; // Assume this exists
import 'screens/donation_tracking_screen.dart'; // Assume this exists
import 'screens/donation_form_screen.dart'; // Add this

void main() {
  runApp(const HopeNestApp());
}

class HopeNestApp extends StatelessWidget {
  const HopeNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HopeNest',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          prefixIconColor: Colors.teal,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/main': (context) => MainScreen(
              userId: ModalRoute.of(context)!.settings.arguments as int,
            ),
        '/super_admin': (context) => const SuperAdminHomeScreen(),
        '/admin_home': (context) => OrphanageAdminHomeScreen(
              userId: ModalRoute.of(context)!.settings.arguments as int,
            ),
        '/edit_orphanage': (context) => EditOrphanageScreen(
              orphanage: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
            ),
        '/donation_tracking': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return DonationTrackingScreen(
            orphanage: args['orphanage'] as Orphanage,
            items: args['items'] as Map<String, int>,
            total: args['total'] as double,
          );
        },
        '/donation_form': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return DonationFormScreen(
            orphanage: args['orphanage'] as Orphanage,
            donorId: args['donorId'] as int,
          );
        },
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final int userId;
  const MainScreen({required this.userId, super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DonorHomeScreen(userId: widget.userId),
      const DonationHistoryScreen(userId: 1), // Placeholder: Update with proper userId
      FeedbackScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
          return SlideTransition(position: offsetAnimation, child: child);
        },
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Donations'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Feedback'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        elevation: 8,
      ),
    );
  }
}