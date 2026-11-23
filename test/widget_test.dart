import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_calculator/screens/calculator_screen.dart';
import 'package:fleet_calculator/screens/login_screen.dart';

void main() {
  testWidgets('login asks for NRP only', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('NRP'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsNothing);
  });

  testWidgets('standard and custom calculation screens are both available',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalculatorScreen()));

    expect(find.text('Fleet Calculator'), findsOneWidget);
    expect(find.text('Parameter Tetap'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: CalculatorScreen(isCustom: true)),
    );

    expect(find.text('Custom Calculation'), findsOneWidget);
    expect(find.text('Parameter Custom'), findsOneWidget);
    expect(find.text('Loading Speed'), findsOneWidget);
    expect(find.text('HITUNG CUSTOM MATCH FACTOR'), findsOneWidget);
  });
}
