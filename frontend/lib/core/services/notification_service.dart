import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/core/network/api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // A global key to show SnackBars from anywhere in the app (even outside widgets)
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  Future<void> init() async {
    // 1. Request Permission from the user
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
      
      // 2. Get the FCM Device Token
      try {
        String? token = await _messaging.getToken();
        print("FCM Token: $token");
        if (token != null) {
          try {
            await ApiClient.patch('/api/auth/fcm-token', {'fcm_token': token});
            print("FCM Token sent to backend successfully.");
          } catch (e) {
            print("FCM Token backend sync skipped (User might not be logged in).");
          }
        }
      } catch (e) {
        print("Error getting FCM token: $e");
      }
      
      // 3. Listen to token refreshes
      _messaging.onTokenRefresh.listen((newToken) async {
        print("FCM Token Refreshed: $newToken");
        try {
          await ApiClient.patch('/api/auth/fcm-token', {'fcm_token': newToken});
        } catch (_) {}
      });

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message received: ${message.notification?.title}');
        
        if (message.notification != null) {
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('${message.notification?.title ?? "New Message"}\n${message.notification?.body ?? ""}'),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      });
    } else {
      print('User declined notification permission');
    }
  }
}
