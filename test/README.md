# SyncLayer Test Suite

Comprehensive test suite for the SyncLayer SDK with 90%+ code coverage target.

## Quick Start

### Run All Tests
```bash
# Unix/Linux/macOS
./test_runner.sh

# Windows
.\test_runner.ps1
```

### Run Specific Test Types
```bash
# Unit tests only (fast, < 1 minute)
./test_runner.sh unit

# Integration tests only (moderate, 2-5 minutes)
./test_runner.sh integration

# Stress tests only (slow, 5-30 minutes)
./test_runner.sh stress

# Quick tests (unit + integration, < 5 minutes)
./test_runner.sh quick
```

### Run Without Coverage
```bash
./test_runner.sh all false
```

## Test Structure

```
test/
├── test_infrastructure.dart      # Shared test utilities and mocks
├── run_all_tests.dart            # Comprehensive test runner
├── TEST_COVERAGE_PLAN.md         # Coverage improvement plan
│
├── unit/                         # Unit tests (60+ tests)
│   ├── sync_engine_test.dart    # SyncEngine component tests
│   ├── local_storage_test.dart  # LocalStorage tests
│   ├── queue_manager_test.dart  # QueueManager tests
│   └── conflict_resolver_test.dart
│
├── integration/                  # Integration tests (40+ tests)
│   ├── full_sync_cycle_test.dart # Complete sync cycle tests
│   ├── sync_flow_test.dart      # Sync flow scenarios
│   └── adapter_integration_test.dart
│
├── stress/                       # Stress tests (15+ tests)
│   └── stress_test.dart         # Performance and scale tests
│
├── comprehensive/                # Comprehensive feature tests (400+ tests)
│   ├── 01_initialization_test.dart
│   ├── 02_crud_operations_test.dart
│   ├── 03_batch_operations_test.dart
│   └── 04_query_operations_test.dart
│
└── [feature tests]              # Individual feature tests
    ├── query_test.dart
    ├── delta_sync_test.dart
    ├── encryption_test.dart
    ├── sync_filter_test.dart
    └── custom_conflict_resolver_test.dart
```

## Test Infrastructure

### TestEnvironment
Provides easy setup/teardown for tests:

```dart
late TestEnvironment env;

setUp(() async {
  env = TestEnvironment();
  await env.setUp();
});

tearDown(() async {
  await env.tearDown();
});

test('example test', () async {
  await env.initSyncLayer(enableAutoSync: false);
  
  // Your test code here
  
  // Environment automatically cleaned up in tearDown
});
```

### MockBackendAdapter
Simulates backend without network calls:

```dart
// Simulate network latency
env.backend.setLatency(Duration(seconds: 1));

// Make operations fail
env.backend.setShouldFail(true);

// Verify backend state
expect(env.backend.pushCallCount, greaterThan(0));
expect(env.backend.getCollectionRecords('test').length, 5);
```

### MockConnectivityPlatform
Control connectivity state:

```dart
// Simulate going offline
env.connectivity.goOffline();

// Simulate coming back online
env.connectivity.goOnline();
```

## Test Categories

### Unit Tests (60+ tests)
Fast, isolated tests for individual components.

**Coverage:**
- SyncEngine: Push/pull sync, conflict resolution, connectivity
- LocalStorage: CRUD operations, encryption, concurrent access
- QueueManager: Operation queuing, retry logic, batch operations
- ConflictResolver: All strategies, custom resolvers

**Run time:** < 1 minute

### Integration Tests (40+ tests)
Tests for complete workflows and component interactions.

**Coverage:**
- Full CRUD sync cycles
- Multi-device simulation
- Offline-to-online transitions
- Error recovery scenarios
- Large dataset handling
- Delta sync integration

**Run time:** 2-5 minutes

### Stress Tests (15+ tests)
Performance and scalability tests.

**Coverage:**
- 10,000+ record handling
- Large documents (1MB+)
- Concurrent operations (100+)
- Rapid successive operations
- Query performance
- Memory management

**Run time:** 5-30 minutes

### Comprehensive Tests (400+ tests)
Detailed feature coverage with edge cases.

**Coverage:**
- Initialization scenarios
- CRUD operations (all data types)
- Batch operations
- Query operations (all operators)
- Watch streams
- Encryption
- Sync filters

**Run time:** 5-10 minutes

## Writing Tests

### Test Template

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

  group('Feature Name', () {
    test('should do something', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Arrange
      final data = createTestData(text: 'Test');

      // Act
      final id = await SyncLayer.collection('test').save(data);

      // Assert
      expect(id, isNotEmpty);
      
      final retrieved = await SyncLayer.collection('test').get(id);
      expect(retrieved, isNotNull);
      expect(retrieved!['text'], 'Test');
    });
  });
}
```

### Best Practices

1. **Use TestEnvironment** - Always use the test infrastructure
2. **Isolate Tests** - Each test should be independent
3. **Clear Names** - Test names should describe what is tested
4. **Arrange-Act-Assert** - Follow AAA pattern
5. **Test Edge Cases** - Include error scenarios
6. **Async Handling** - Use `await waitForSync()` for async operations
7. **Cleanup** - Always dispose resources in tearDown
8. **Timeouts** - Add timeouts for long-running tests
9. **Assertions** - Verify expected behavior explicitly
10. **No Flaky Tests** - Tests should be deterministic

## Coverage Goals

| Component | Current | Target |
|-----------|---------|--------|
| SyncEngine | 60% | 95% |
| LocalStorage | 50% | 90% |
| QueueManager | 40% | 90% |
| ConflictResolver | 70% | 95% |
| QueryBuilder | 80% | 95% |
| Adapters | 30% | 85% |
| Encryption | 60% | 90% |
| RealTime | 40% | 85% |
| **Overall** | **40%** | **90%** |

## Viewing Coverage

### Generate Coverage Report
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows
```

### VS Code Coverage
Install the "Coverage Gutters" extension and run:
```bash
flutter test --coverage
```

Coverage will be displayed inline in your editor.

## Continuous Integration

### GitHub Actions Example
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
      - uses: codecov/codecov-action@v2
        with:
          files: ./coverage/lcov.info
```

## Troubleshooting

### Tests Fail with "Binding not initialized"
Make sure you're using `TestEnvironment` which calls `TestWidgetsFlutterBinding.ensureInitialized()`.

### Isar Errors
Ensure Isar core is initialized:
```dart
await Isar.initializeIsarCore(download: false);
```

### Path Provider Errors
Use `MockPathProviderPlatform` from test_infrastructure.dart.

### Connectivity Errors
Use `MockConnectivityPlatform` from test_infrastructure.dart.

### Flaky Tests
- Add proper `await waitForSync()` calls
- Increase timeouts for slow operations
- Ensure proper cleanup in tearDown
- Check for race conditions

## Contributing

When adding new features:
1. Write tests first (TDD)
2. Aim for 90%+ coverage
3. Include edge cases
4. Update this README
5. Run full test suite before PR

## Resources

- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Test Coverage Best Practices](https://martinfowler.com/bliki/TestCoverage.html)
