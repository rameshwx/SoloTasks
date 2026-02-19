import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solotasks/app/shell_scaffold.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AppShellScaffold()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('calendar tab removes agenda/timeline toggle and highlights',
      (tester) async {
    await pumpShell(tester);
    await tapTab(tester, 'Calendar');

    expect(find.text('Upcoming Highlights'), findsNothing);
    expect(find.text('Agenda'), findsNothing);
    expect(find.text('Timeline'), findsNothing);
  });

  testWidgets('tasks tab removes smart lists section', (tester) async {
    await pumpShell(tester);
    await tapTab(tester, 'Tasks');

    expect(find.text('Smart Lists'), findsNothing);
    expect(find.text('Recent Results'), findsOneWidget);
  });

  testWidgets('settings tab removes export/system-theme and keeps new controls',
      (tester) async {
    await pumpShell(tester);
    await tapTab(tester, 'Settings');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Export / Import'), findsNothing);
    expect(find.text('Follow System Theme'), findsNothing);
    expect(find.text('Reminder defaults'), findsOneWidget);
    expect(find.text('Week start'), findsOneWidget);
    expect(find.text('Time format'), findsOneWidget);
  });
}
