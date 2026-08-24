class DashboardStats {
  final int totalPatients;
  final int totalAppointments;
  final int pendingAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final int unreadMessages;
  final int totalServices;
  final double revenueToday;
  final double revenueWeek;
  final double revenueMonth;
  final double noShowRate;
  final Map<String, int> appointmentTypeBreakdown;
  
  // Patient specific fields
  final String? heartRate;
  final String? bloodPressure;
  final String? glucose;
  final String? temperature;
  final String? lastExamDate;
  final String? lastPrescriptionDate;

  const DashboardStats({
    required this.totalPatients,
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.unreadMessages,
    required this.totalServices,
    required this.revenueToday,
    required this.revenueWeek,
    required this.revenueMonth,
    required this.noShowRate,
    required this.appointmentTypeBreakdown,
    this.heartRate,
    this.bloodPressure,
    this.glucose,
    this.temperature,
    this.lastExamDate,
    this.lastPrescriptionDate,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final breakdown = (json['appointment_type_breakdown'] as Map<String, dynamic>?) ?? {};
    return DashboardStats(
      totalPatients: json['total_patients'] as int,
      totalAppointments: json['total_appointments'] as int,
      pendingAppointments: json['pending_appointments'] as int,
      completedAppointments: json['completed_appointments'] as int,
      cancelledAppointments: json['cancelled_appointments'] as int,
      unreadMessages: json['unread_messages'] as int,
      totalServices: json['total_services'] as int,
      revenueToday: (json['revenue_today'] as num).toDouble(),
      revenueWeek: (json['revenue_week'] as num).toDouble(),
      revenueMonth: (json['revenue_month'] as num).toDouble(),
      noShowRate: (json['no_show_rate'] as num).toDouble(),
      appointmentTypeBreakdown: breakdown.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      ),
      heartRate: json['heart_rate'] as String?,
      bloodPressure: json['blood_pressure'] as String?,
      glucose: json['glucose'] as String?,
      temperature: json['temperature'] as String?,
      lastExamDate: json['last_exam_date'] as String?,
      lastPrescriptionDate: json['last_prescription_date'] as String?,
    );
  }
}
