import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  final String _baseUrl = AppConstants.baseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String role,
    String? dob,
    String? gender,
    String? orphanageName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
        'dob': dob,
        'gender': gender,
        'orphanageName': orphanageName,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Sign-up failed');
    }
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getOrphanages(String location) async {
    final response = await http.get(Uri.parse('$_baseUrl/orphanages?location=$location'));
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch orphanages');
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getOrphanageForAdmin(int adminId) async {
    final response = await http.get(Uri.parse('$_baseUrl/orphanage/admin/$adminId'));
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch orphanage');
    }
    return jsonDecode(response.body);
  }

  Future<void> createOrphanage({
    required String name,
    required String location,
    required String contact,
    String? description,
    List<String>? needs,
    String? imageUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/orphanages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'location': location,
        'contact': contact,
        'description': description,
        'needs': needs ?? [],
        'image_url': imageUrl,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to create orphanage');
    }
  }

  Future<void> updateOrphanage({
    required int orphanageId,
    required String name,
    required String location,
    required String contact,
    String? description,
    List<String>? needs,
    String? imageUrl,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/orphanages/$orphanageId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'location': location,
        'contact': contact,
        'description': description,
        'needs': needs ?? [],
        'image_url': imageUrl,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to update orphanage');
    }
  }

  Future<void> addDonation(int orphanageId, int donorId, Map<String, int> items, double total) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/donations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'orphanageId': orphanageId,
        'donorId': donorId,
        'items': items,
        'total': total,
        'status': 'pending',
      }),
    );
    final result = jsonDecode(response.body);
    if (!result['success']) {
      throw Exception(result['message'] ?? 'Failed to add donation');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/user/$userId'));
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch user profile');
    }
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getDonations({int? orphanageId}) async {
    final uri = orphanageId != null
        ? Uri.parse('$_baseUrl/donations?orphanage_id=$orphanageId')
        : Uri.parse('$_baseUrl/donations');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch donations');
    }
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getDonationsByDonor(int donorId) async {
    final response = await http.get(Uri.parse('$_baseUrl/donations/donor/$donorId'));
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch donor donations');
    }
    return jsonDecode(response.body);
  }

  Future<void> updateDonationStatus(int donationId, String status) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/donations/$donationId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to update donation status');
    }
  }

  Future<void> deleteUser(int userId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/users/$userId'));
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to delete user');
    }
  }

  Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse('$_baseUrl/users'));
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch users');
    }
    return jsonDecode(response.body);
  }

  Future<void> logout() async {
    final response = await http.post(Uri.parse('$_baseUrl/logout'));
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to logout');
    }
  }

  Future<void> submitFeedback(int userId, String feedback) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/feedback'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'feedback': feedback}),
    );
    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to submit feedback');
    }
  }
}