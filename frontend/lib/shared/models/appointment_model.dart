import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class PatientInfo {
  final int id;
  final String name;
  final DateTime? dateOfBirth;

  const PatientInfo({
    required this.id,
    required this.name,
    this.dateOfBirth,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
    );
  }
}

class AppointmentModel {
  final int id;
  final int patientId;
  final int doctorId;
  final String? doctorNameFromApi;
  final String? medicoName;
  final DateTime appointmentDate;
  final int durationMinutes;
  final String type;
  final String status;
  final String? reason;
  final String? notes;
  final String? symptoms;
  final String? diagnosis;
  final String? prescription;
  final String? examUrl;
  final String? examSummary;
  final String? weight;
  final String? height;
  final String? heartRate;
  final String? bloodPressure;
  final String? glucose;
  final String? temperature;
  final double price;
  final bool paid;
  final String? paymentMethod;
  final PatientInfo? patient;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.doctorNameFromApi,
    this.medicoName,
    required this.appointmentDate,
    required this.durationMinutes,
    required this.type,
    required this.status,
    this.reason,
    this.notes,
    this.symptoms,
    this.diagnosis,
    this.prescription,
    this.examUrl,
    this.examSummary,
    this.weight,
    this.height,
    this.heartRate,
    this.bloodPressure,
    this.glucose,
    this.temperature,
    required this.price,
    required this.paid,
    this.paymentMethod,
    this.patient,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int,
      patientId: json['patient_id'] as int,
      doctorId: json['doctor_id'] as int,
      doctorNameFromApi: json['doctor_name'] as String?,
      medicoName: json['medico_name'] as String?,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      type: json['type'] as String? ?? 'consultation',
      status: json['status'] as String? ?? 'pending',
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      symptoms: json['symptoms'] as String?,
      diagnosis: json['diagnosis'] as String?,
      prescription: json['prescription'] as String?,
      examUrl: json['exam_url'] as String?,
      examSummary: json['exam_summary'] as String?,
      weight: json['weight'] as String?,
      height: json['height'] as String?,
      heartRate: json['heart_rate'] as String?,
      bloodPressure: json['blood_pressure'] as String?,
      glucose: json['glucose'] as String?,
      temperature: json['temperature'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      paid: json['paid'] as bool? ?? false,
      paymentMethod: json['payment_method'] as String?,
      patient: json['patient'] != null
          ? PatientInfo.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  AppointmentModel copyWith({
    String? status,
    String? notes,
    String? symptoms,
    String? diagnosis,
    String? prescription,
    String? examUrl,
    String? examSummary,
    String? weight,
    String? height,
    String? heartRate,
    String? bloodPressure,
    String? glucose,
    String? temperature,
    bool? paid,
    String? paymentMethod,
  }) {
    return AppointmentModel(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      doctorNameFromApi: doctorNameFromApi,
      medicoName: medicoName,
      appointmentDate: appointmentDate,
      durationMinutes: durationMinutes,
      type: type,
      status: status ?? this.status,
      reason: reason,
      notes: notes ?? this.notes,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      examUrl: examUrl ?? this.examUrl,
      examSummary: examSummary ?? this.examSummary,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      heartRate: heartRate ?? this.heartRate,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      glucose: glucose ?? this.glucose,
      temperature: temperature ?? this.temperature,
      price: price,
      paid: paid ?? this.paid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get doctorName => medicoName ?? doctorNameFromApi ?? 'Médico $doctorId';

  String get patientName => patient?.name ?? 'Paciente #$patientId';
  String get patientDob {
    if (patient?.dateOfBirth == null) return 'N/A';
    final dob = patient!.dateOfBirth!;
    return '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}';
  }
}
Color statusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.pending;
    case 'confirmed':
      return AppColors.confirmed;
    case 'in_progress':
      return AppColors.primary;
    case 'no_show':
      return AppColors.textHint;
    case 'completed':
      return AppColors.completed;
    case 'cancelled':
      return AppColors.cancelled;
    default:
      return AppColors.textSecondary;
  }
}

String typeLabel(String type) {
  switch (type) {
    case 'consultation':
      return 'Consulta';
    case 'exam':
      return 'Exame';
    case 'return':
      return 'Retorno';
    default:
      return type;
  }
}

String statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Pendente';
    case 'confirmed':
      return 'Confirmado';
    case 'in_progress':
      return 'Em Andamento';
    case 'no_show':
      return 'Não compareceu';
    case 'completed':
      return 'Concluído';
    case 'cancelled':
      return 'Cancelado';
    default:
      return status;
  }
}
