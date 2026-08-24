import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/shared/widgets/custom_app_bar.dart';

/// 🧪 CustomAppBar Widget Test
/// Responsabilidade: qa-test-engineer
void main() {
  testWidgets('CustomAppBar renders subtitle, app bar title and controls theme', (
    WidgetTester tester,
  ) async {
    // 1. Defina um subtitle de teste
    const testSubtitle = 'Sua Saúde de Forma Inteligente';

    // 2. Monte o widget sob o ProviderScope e MaterialApp
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            appBar: CustomAppBar(
              subtitle: testSubtitle,
              showProfileButton: false,
              showThemeButton: true,
            ),
          ),
        ),
      ),
    );

    // 3. Verifique se o título principal da aplicação "Sua Consulta" é exibido
    expect(find.text('Sua Consulta'), findsOneWidget);

    // 4. Verifique se o subtítulo customizado é exibido
    expect(find.text(testSubtitle), findsOneWidget);

    // 5. Verifique se o ícone do botão de toggle de tema está presente
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);

    // 6. Toque no botão de toggle de tema
    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();

    // 7. Como o tema mudou para escuro, o botão deve agora mostrar o ícone de light_mode
    expect(find.byIcon(Icons.light_mode), findsOneWidget);
  });
}
