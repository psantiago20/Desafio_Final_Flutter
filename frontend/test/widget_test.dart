import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart'; 

/// 🧪 Basic App Load Test
/// Responsabilidade: qa-test-engineer
void main() {
  testWidgets('App starts and shows MainDashboardScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OmniConnectApp());

    // Verify that the bottom navigation bar is rendered
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify that the Agenda screen is the default one
    expect(find.text('Minha Agenda'), findsOneWidget);
    
    // Verify that tabs Consultas and Exames exist
    expect(find.text('Consultas'), findsOneWidget);
    expect(find.text('Exames'), findsOneWidget);
  });
}
