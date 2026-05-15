class UserModel {
  final int id;
  final String email;
  final String username;
  final String? fullName;
  final String? phone;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.phone,
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
      phone: json['phone'] as String?,
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
        'phone': phone,
        'role': role,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };


  String get displayName => fullName ?? username;

  String get salutationName {
    if (isDoctor) {
      if (displayName.startsWith('Dr.') || displayName.startsWith('Dra.')) {
        return displayName;
      }
      return 'Dr. $displayName';
    }
    return displayName;
  }

  String get shortSalutationName {
    if (isDoctor) {
      if (displayName.startsWith('Dr.') || displayName.startsWith('Dra.')) {
        final parts = displayName.split(' ');
        return parts.length >= 2 ? '${parts[0]} ${parts[1]}' : parts[0];
      }
      return 'Dr. ${displayName.split(' ').first}';
    }
    return displayName.split(' ').first;
  }

  bool get isDoctor => role == 'doctor';
  bool get isAdmin => role == 'admin';
}
