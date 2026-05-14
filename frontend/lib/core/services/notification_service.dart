import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app_router.dart';
import 'package:frontend/core/network/api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // A global key to show SnackBars from anywhere in the app (even outside widgets)
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  void _handleNotificationClick(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    
    final type = data['type'];
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    
    switch (type) {
      case 'appointment_created':
      case 'appointment_cancelled':
      case 'appointment_deleted':
        context.go('/appointments');
        break;
      case 'chat_message':
        // TODO: Update route to the future chat screen when implemented
        // For now, fallback to dashboard
        context.go('/dashboard');
        break;
    }
  }

  Future<void> init() async {
    // 1. Request Permission from the user
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
      
      // 2. Get the FCM Device Token
      try {
        String? token = await _messaging.getToken();
        debugPrint("FCM Token: $token");
        if (token != null) {
          try {
            await ApiClient.patch('/api/auth/fcm-token', {'fcm_token': token});
            debugPrint("FCM Token sent to backend successfully.");
          } catch (e) {
            debugPrint("FCM Token backend sync skipped (User might not be logged in).");
          }
        }
      } catch (e) {
        debugPrint("Error getting FCM token: $e");
      }
      
      // 3. Listen to token refreshes
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint("FCM Token Refreshed: $newToken");
        try {
          await ApiClient.patch('/api/auth/fcm-token', {'fcm_token': newToken});
        } catch (_) {}
      });

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message received: ${message.notification?.title}');
        
        if (message.notification != null) {
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('${message.notification?.title ?? "New Message"}\n${message.notification?.body ?? ""}'),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.blueAccent,
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  _handleNotificationClick(message.data);
                },
              ),
            ),
          );
        }
      });

      // 5. Handle Background Message Taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notification tapped in background: ${message.data}');
        _handleNotificationClick(message.data);
      });

      // 6. Handle Terminated Message Taps
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('App launched from terminated state via notification: ${initialMessage.data}');
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationClick(initialMessage.data);
        });
      }
    } else {
      debugPrint('User declined notification permission');
    }
  }
}
