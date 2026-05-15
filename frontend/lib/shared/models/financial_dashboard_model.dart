class FinancialDashboardModel {
  final double revenueToday;
  final double revenueMonth;
  final double revenueYear;
  final double totalRevenue;
  final List<DayCount> appointmentsByDayOfWeek;
  final List<HourCount> appointmentsByTimeOfDay;

  FinancialDashboardModel({
    required this.revenueToday,
    required this.revenueMonth,
    required this.revenueYear,
    required this.totalRevenue,
    required this.appointmentsByDayOfWeek,
    required this.appointmentsByTimeOfDay,
  });

  factory FinancialDashboardModel.fromJson(Map<String, dynamic> json) {
    return FinancialDashboardModel(
      revenueToday: (json['revenue_today'] ?? 0).toDouble(),
      revenueMonth: (json['revenue_month'] ?? 0).toDouble(),
      revenueYear: (json['revenue_year'] ?? 0).toDouble(),
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      appointmentsByDayOfWeek: (json['appointments_by_day_of_week'] as List<dynamic>?)
              ?.map((e) => DayCount.fromJson(e))
              .toList() ??
          [],
      appointmentsByTimeOfDay: (json['appointments_by_time_of_day'] as List<dynamic>?)
              ?.map((e) => HourCount.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DayCount {
  final String day;
  final int count;

  DayCount({required this.day, required this.count});

  factory DayCount.fromJson(Map<String, dynamic> json) {
    return DayCount(
      day: json['day'],
      count: json['count'],
    );
  }
}

class HourCount {
  final String hour;
  final int count;

  HourCount({required this.hour, required this.count});

  factory HourCount.fromJson(Map<String, dynamic> json) {
    return HourCount(
      hour: json['hour'],
      count: json['count'],
    );
  }
}
