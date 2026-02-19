import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solotasks/app/shell_scaffold.dart';

void main() {
  testWidgets('bottom nav is locked to 4 required tabs', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AppShellScaffold()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(find.byType(InkWell), findsWidgets);
  });
}
