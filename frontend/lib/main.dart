import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/token_storage.dart';
import 'package:frontend/app_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:frontend/core/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("⚠️ Erro ao inicializar o Firebase: $e");
  }

  try {
    await initializeDateFormatting('pt_BR', null);
  } catch (e) {
    debugPrint("⚠️ Erro ao inicializar formatação de datas: $e");
  }

  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    debugPrint("⚠️ Erro ao carregar arquivo .env: $e");
  }

  try {
    await TokenStorage.init();
  } catch (e) {
    debugPrint("⚠️ Erro ao inicializar TokenStorage: $e");
  }

  try {
    // Initialize the notification service (Request permission & get token)
    await NotificationService().init();
  } catch (e) {
    debugPrint("⚠️ Erro ao inicializar NotificationService: $e");
  }

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
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeProvider),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      scaffoldMessengerKey: NotificationService().scaffoldMessengerKey,
    );
  }
}