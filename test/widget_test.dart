import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:staffportal/view/requests/requests_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('requests screen shows leave and transfer sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RequestsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Leave Requests'), findsOneWidget);
    expect(find.text('Transfer Requests'), findsOneWidget);
    expect(find.text('View Details'), findsWidgets);
  });
}
