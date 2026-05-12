import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🧪 Basic App Load Test
/// Responsabilidade: qa-test-engineer
void main() {
  testWidgets('App starts and shows MainDashboardScreen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    // await tester.pumpWidget(const OmniConnectApp());

    // Verify that the bottom navigation bar is rendered (now using Material 3 NavigationBar)
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify that the Home screen is the default one (has the 'Portal do Paciente' text)
    expect(find.text('Portal do Paciente'), findsOneWidget);

    // Verify that tabs Consultas and Exames exist in the bottom bar
    expect(find.text('Consultas'), findsWidgets);
    expect(find.text('Exames'), findsWidgets);
  });
}
