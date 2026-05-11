import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/token_storage.dart';
import 'package:frontend/app_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await dotenv.load(fileName: "assets/.env");
  await TokenStorage.init();

  runApp(
    const ProviderScope(
      child: OmniConnectApp(),
    ),
  );
}

class OmniConnectApp extends ConsumerWidget {
  const OmniConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'OmniConnect',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}