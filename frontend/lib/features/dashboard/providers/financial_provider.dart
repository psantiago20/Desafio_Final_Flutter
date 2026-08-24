import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/shared/models/financial_dashboard_model.dart';

final financialDashboardProvider = FutureProvider.autoDispose<FinancialDashboardModel>((ref) async {
  final response = await ApiClient.get('/api/dashboard/financial');
  return FinancialDashboardModel.fromJson(response);
});


