class UserModel {
  final int id;
  final String email;
  final String username;
  final String? fullName;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'full_name': fullName,
        'role': role,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  String get displayName => fullName ?? username;

  bool get isDoctor => role == 'doctor';
  bool get isAdmin => role == 'admin';
}
