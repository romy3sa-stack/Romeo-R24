import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:receipt24/main.dart';

void main() {
  testWidgets('Receipt24App renders the platform status screen', (tester) async {
    await tester.pumpWidget(const Receipt24App());
    // Supabase initialization is async and (in this offline test
    // environment) will fail to reach a network — pump once so the initial
    // frame renders before that resolves/rejects.
    await tester.pump();

    expect(find.text('Every Receipt. One Place.'), findsOneWidget);
    expect(find.text('Phase 1 & 2 — Platform Foundation'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
