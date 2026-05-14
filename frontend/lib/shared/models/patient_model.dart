class PatientModel {
  final int id;
  final String name;
  final String? email;
  final String phone;
  final String? whatsapp;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? state;
  final String? cpf;
  final String? rg;
  final String? insurance;
  final String? insuranceNumber;
  final String? notes;
  final String? tags;
  final String? bloodType;
  final String? allergies;
  final String? chronicConditions;
  final String? medications;
  final String? heartRate;
  final String? bloodPressure;
  final String? glucose;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientModel({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    this.whatsapp,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.state,
    this.cpf,
    this.rg,
    this.insurance,
    this.insuranceNumber,
    this.notes,
    this.tags,
    this.bloodType,
    this.allergies,
    this.chronicConditions,
    this.medications,
    this.heartRate,
    this.bloodPressure,
    this.glucose,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String,
      whatsapp: json['whatsapp'] as String?,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth'] as String) : null,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      cpf: json['cpf'] as String?,
      rg: json['rg'] as String?,
      insurance: json['insurance'] as String?,
      insuranceNumber: json['insurance_number'] as String?,
      notes: json['notes'] as String?,
      tags: json['tags'] as String?,
      bloodType: json['blood_type'] as String?,
      allergies: json['allergies'] as String?,
      chronicConditions: json['chronic_conditions'] as String?,
      medications: json['medications'] as String?,
      heartRate: json['heart_rate'] as String?,
      bloodPressure: json['blood_pressure'] as String?,
      glucose: json['glucose'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'city': city,
      'state': state,
      'cpf': cpf,
      'rg': rg,
      'insurance': insurance,
      'insurance_number': insuranceNumber,
      'notes': notes,
      'tags': tags,
      'blood_type': bloodType,
      'allergies': allergies,
      'chronic_conditions': chronicConditions,
      'medications': medications,
      'heart_rate': heartRate,
      'blood_pressure': bloodPressure,
      'glucose': glucose,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
