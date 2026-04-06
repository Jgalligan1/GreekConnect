import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('GreekConnect'),
          ),
        ),
      ),
    );

    expect(find.text('GreekConnect'), findsOneWidget);
  });
}
