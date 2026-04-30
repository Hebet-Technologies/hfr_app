import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:staffportal/model/staff_portal_access.dart';
import 'package:staffportal/model/user_model.dart';
import 'package:staffportal/view/requests/requests_screen.dart';
import 'package:staffportal/view/training/training_screen.dart';
import 'package:staffportal/view_model/providers.dart';

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
    expect(find.text('View Leave'), findsOneWidget);
    expect(find.text('View Transfers'), findsOneWidget);
  });

  testWidgets(
    'loan form dropdowns accept selections without assertion errors',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoanRequestFormScreen())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('Loan Type::null')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emergency Loan').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('Repayment Period::null')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12 Months').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(
        find.byKey(const ValueKey('Repayment Period::12 Months')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'training screen lays out approver mode cards without flex errors',
    (WidgetTester tester) async {
      final approverUser = UserModel(
        userId: '1',
        email: 'approver@example.com',
        fullName: 'Approver User',
        loginStatus: 'active',
        workingStationId: 'ws-1',
        workingStationName: 'HQ',
        personalInformationId: 'pi-1',
        employmentInformationId: 'ei-1',
        payroll: 'PAY-1',
        token: 'token',
        roles: const [],
        permissions: const ['view training request'],
      );
      final approverAccess = StaffPortalAccess.fromUser(
        approverUser,
        preferredMode: StaffPortalMode.approver,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffPortalAccessProvider.overrideWithValue(approverAccess),
          ],
          child: const MaterialApp(home: TrainingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Training'), findsOneWidget);
      expect(
        find.text('No training applications are waiting for review.'),
        findsOneWidget,
      );

      await tester.tap(find.text('All Trainings'));
      await tester.pumpAndSettle();

      expect(find.text('View Details'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
