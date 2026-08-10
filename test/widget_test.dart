import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:performance_demo/home_screen.dart';

void main() {
  testWidgets('Home screen renders the playground menu', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // The app bar title is present.
    expect(find.text('Performance Playground'), findsOneWidget);

    // A couple of the demo entries render in the list.
    expect(find.text('Counter panel'), findsOneWidget);
    expect(find.text('Product search'), findsOneWidget);
  });
}
