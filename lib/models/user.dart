class User {
  final int id;
  final String email;
  final String role;
  final String? dob;
  final String? gender;

  User({
    required this.id,
    required this.email,
    required this.role,
    this.dob,
    this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      dob: json['dob'],
      gender: json['gender'],
    );
  }
}