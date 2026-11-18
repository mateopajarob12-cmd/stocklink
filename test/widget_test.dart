import 'package:flutter_test/flutter_test.dart';
import 'package:stocklink/main.dart';

void main() {
  testWidgets('La app arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const StockLinkApp());
    expect(find.text('StockLink'), findsOneWidget);
  });
}