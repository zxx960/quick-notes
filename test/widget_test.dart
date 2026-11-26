import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_notes/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('quick note can be added and shown', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const QuickNotesApp());
    await tester.pumpAndSettle();

    expect(find.text('随手记'), findsOneWidget);
    expect(find.text('还没有笔记'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '买牛奶');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();

    expect(find.text('买牛奶'), findsOneWidget);
    expect(find.text('还没有笔记'), findsNothing);
  });
}
