import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil_devone/core/config/app_config.dart';
import 'package:movil_devone/main.dart';

void main() {
  testWidgets('OneDevApp login smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppConfig.init();

    await tester.pumpWidget(const OneDevApp());
    await tester.pumpAndSettle();

    expect(find.text('DevOne Móvil'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
