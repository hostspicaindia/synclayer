import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';
import 'package:todo/main.dart';
import 'package:todo/screens/todo_screen.dart';

/// Mock backend adapter for testing
class MockBackendAdapter implements SyncBackendAdapter {
  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {}

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    return [];
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {}

  @override
  void updateAuthToken(String token) {}
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize SyncLayer with mock adapter for testing
    await SyncLayer.init(
      SyncConfig(
        customBackendAdapter: MockBackendAdapter(),
        enableAutoSync: false,
        collections: ['todos'],
      ),
    );
  });

  tearDownAll(() async {
    await SyncLayer.dispose();
  });

  testWidgets('Todo app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify the app loads
    expect(find.byType(TodoScreen), findsOneWidget);

    // Verify we can see the todo list (even if empty)
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('Can add a todo', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Find and tap the add button
    final addButton = find.byIcon(Icons.add);
    expect(addButton, findsOneWidget);

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify dialog appears (or whatever your UI does)
    // Adjust this based on your actual UI
  });
}
