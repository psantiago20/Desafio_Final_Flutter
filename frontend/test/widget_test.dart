import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart'; 

/// 🧪 Basic App Load Test
/// Responsabilidade: qa-test-engineer
void main() {
  testWidgets('App starts and shows ClientHomeScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OmniConnectApp());

    // Verify that the home screen title is rendered
    expect(find.text('Meus Agendamentos'), findsOneWidget);
    
    // Verify that there is a floating action button
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
