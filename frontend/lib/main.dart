import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/token_storage.dart';
import 'package:frontend/app_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:frontend/core/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeDateFormatting('pt_BR', null);
  await dotenv.load(fileName: "assets/.env");
  await TokenStorage.init();

  // Initialize the notification service (Request permission & get token)
  await NotificationService().init();

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
      scaffoldMessengerKey: NotificationService().scaffoldMessengerKey,
    );
  }
}