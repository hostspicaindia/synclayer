# Testing Quick Start Guide

Get up and running with SyncLayer tests in 5 minutes.

## Prerequisites

- Flutter SDK installed
- SyncLayer dependencies installed (`flutter pub get`)
- (Optional) lcov for coverage reports

## Run Tests

### Option 1: Using Test Runners (Recommended)

**Unix/Linux/macOS:**
```bash
chmod +x test_runner.sh
./test_runner.sh
```

**Windows:**
```powershell
.\test_runner.ps1
```

### Option 2: Using Flutter Command

```bash
# All tests
flutter test

# Specific test file
flutter test test/unit/sync_engine_test.dart

# With coverage
flutter test --coverage
```

## Test Types

### Quick Tests (< 1 minute)
```bash
./test_runner.sh unit
```
Runs fast unit tests for rapid development feedback.

### Integration Tests (2-5 minutes)
```bash
./test_runner.sh integration
```
Tests complete workflows and component interactions.

### Stress Tests (5-30 minutes)
```bash
./test_runner.sh stress
```
Performance and scalability tests with large datasets.

### All Tests (< 10 minutes)
```bash
./test_runner.sh all
```
Complete test suite with coverage report.

## View Coverage

### Automatic (with test runner)
```bash
./test_runner.sh all true
```
Generates and opens HTML coverage report automatically.

### Manual
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
```

### VS Code
1. Install "Coverage Gutters" extension
2. Run: `flutter test --coverage`
3. Click "Watch" in status bar
4. Coverage shown inline in editor

## Writing Your First Test

1. **Create test file** in appropriate directory:
   - `test/unit/` for unit tests
   - `test/integration/` for integration tests
   - `test/stress/` for stress tests

2. **Use the template:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';
import '../test_infrastructure.dart';

void main() {
  late TestEnvironment env;

  setUp(() async {
    env = TestEnvironment();
    await env.setUp();
  });

  tearDown(() async {
    await env.tearDown();
  });

  group('My Feature', () {
    test('should work correctly', () async {
      // Initialize SyncLayer
      await env.initSyncLayer(enableAutoSync: false);

      // Your test code
      final id = await SyncLayer.collection('test').save({
        'text': 'Test data',
      });

      // Assertions
      expect(id, isNotEmpty);
    });
  });
}
```

3. **Run your test:**
```bash
flutter test test/unit/my_feature_test.dart
```

## Common Issues

### "Binding has not yet been initialized"
**Solution**: Use `TestEnvironment` which handles initialization.

### "Isar not initialized"
**Solution**: `TestEnvironment` handles this automatically.

### "Path provider error"
**Solution**: `TestEnvironment` provides mock path provider.

### Tests are flaky
**Solution**: Add `await waitForSync()` after async operations.

## Test Infrastructure Features

### Mock Backend
```dart
// Simulate network latency
env.backend.setLatency(Duration(seconds: 1));

// Make operations fail
env.backend.setShouldFail(true);

// Check backend state
expect(env.backend.pushCallCount, greaterThan(0));
```

### Mock Connectivity
```dart
// Go offline
env.connectivity.goOffline();

// Come back online
env.connectivity.goOnline();
```

### Test Helpers
```dart
// Wait for async operations
await waitForSync();

// Create test data
final data = createTestData(
  text: 'Test',
  number: 42,
  tags: ['test', 'mock'],
);
```

## CI/CD Integration

### GitHub Actions
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
```

## Next Steps

1. ✅ Run tests: `./test_runner.sh`
2. ✅ View coverage: Check `coverage/html/index.html`
3. ✅ Write tests: Use template above
4. ✅ Read docs: See `test/README.md` for details

## Resources

- **Test Suite README**: `test/README.md`
- **Coverage Plan**: `test/TEST_COVERAGE_PLAN.md`
- **Improvements Summary**: `TEST_COVERAGE_IMPROVEMENTS.md`
- **Example Tests**: `test/unit/sync_engine_test.dart`

## Support

- 📖 [Flutter Testing Guide](https://flutter.dev/docs/testing)
- 🐛 [Report Issues](https://github.com/hostspicaindia/synclayer/issues)
- 💬 [Discussions](https://github.com/hostspicaindia/synclayer/discussions)

---

**Ready to test?** Run `./test_runner.sh` and see your coverage improve! 🚀
