import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:learning/core/theme/app_theme.dart';
import 'package:learning/core/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState renders its icon and message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EmptyState(
            icon: Icons.inbox_outlined,
            message: 'No data yet',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('No data yet'), findsOneWidget);
  });
}
