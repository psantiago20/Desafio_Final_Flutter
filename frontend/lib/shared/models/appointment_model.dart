import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class AppointmentModel {
  final int id;
  final int patientId;
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
  final double price;
  final bool paid;
  final String? paymentMethod;
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
    required this.price,
    required this.paid,
    this.paymentMethod,
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
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      paid: json['paid'] as bool? ?? false,
      paymentMethod: json['payment_method'] as String?,
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
      price: price,
      paid: paid ?? this.paid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get doctorName => medicoName ?? doctorNameFromApi ?? 'Médico $doctorId';
}
Color statusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.pending;
    case 'confirmed':
      return AppColors.confirmed;
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
    case 'completed':
      return 'Concluído';
    case 'cancelled':
      return 'Cancelado';
    default:
      return status;
  }
}
