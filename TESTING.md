# SyncLayer Testing Guide

## Overview

SyncLayer includes comprehensive test coverage across unit tests, integration tests, and performance benchmarks.

## Test Structure

```
test/
├── unit/                      # Unit tests for individual components
│   ├── local_storage_test.dart
│   ├── conflict_resolver_test.dart
│   └── queue_manager_test.dart
├── integration/               # Integration tests for full workflows
│   └── sync_flow_test.dart
├── performance/               # Performance benchmarks
│   └── benchmark_test.dart
└── test_all.dart             # Test runner
```

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test Suite
```bash
# Unit tests only
flutter test test/unit/

# Integration tests only
flutter test test/integration/

# Performance benchmarks only
flutter test test/performance/
```

### Run Single Test File
```bash
flutter test test/unit/local_storage_test.dart
```

### Run with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Categories

### 1. Unit Tests

Test individual components in isolation.

**LocalStorage Tests** (`test/unit/local_storage_test.dart`)
- Save and retrieve data
- Update existing data
- Soft delete operations
- Get all data in collection
- Get unique collections
- Mark records as synced

**ConflictResolver Tests** (`test/unit/conflict_resolver_test.dart`)
- Last-write-wins strategy
- Server-wins strategy
- Client-wins strategy
- Timestamp comparison

**QueueManager Tests** (`test/unit/queue_manager_test.dart`)
- Queue insert operations
- Queue update operations
- Queue delete operations
- Mark operations as syncing/synced/failed
- Increment retry count

### 2. Integration Tests

Test complete workflows end-to-end.

**Sync Flow Tests** (`test/integration/sync_flow_test.dart`)
- Save data locally and sync to backend
- Handle batch operations
- Handle delete operations
- Pull remote data and merge locally
- Handle conflict resolution
- Emit sync events

### 3. Performance Benchmarks

Measure performance characteristics.

**Benchmark Tests** (`test/performance/benchmark_test.dart`)
- Save 100 records (target: < 5s)
- Batch save 100 records (target: < 5s)
- Retrieve 100 records (target: < 1s)
- Delete 100 records (target: < 3s)
- Watch stream updates
- Concurrent operations (50 saves)

## Writing New Tests

### Unit Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/your_module.dart';

void main() {
  group('YourComponent', () {
    late YourComponent component;

    setUp(() {
      component = YourComponent();
    });

    tearDown(() {
      // Clean up
    });

    test('should do something', () {
      // Arrange
      final input = 'test';

      // Act
      final result = component.doSomething(input);

      // Assert
      expect(result, equals('expected'));
    });
  });
}
```

### Integration Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

void main() {
  group('Feature Integration Tests', () {
    setUp(() async {
      await SyncLayer.init(SyncConfig(
        baseUrl: 'https://test.example.com',
        enableAutoSync: false,
      ));
    });

    tearDown(() async {
      await SyncLayer.dispose();
    });

    test('should complete workflow', () async {
      // Test full workflow
    });
  });
}
```

### Performance Test Template

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('benchmark: operation name', () async {
    final stopwatch = Stopwatch()..start();

    // Perform operation

    stopwatch.stop();
    print('Time: ${stopwatch.elapsedMilliseconds}ms');
    expect(stopwatch.elapsedMilliseconds, lessThan(targetMs));
  });
}
```

## Test Best Practices

### 1. Isolation
- Each test should be independent
- Use setUp/tearDown for initialization and cleanup
- Don't rely on test execution order

### 2. Clarity
- Use descriptive test names
- Follow Arrange-Act-Assert pattern
- One assertion per test (when possible)

### 3. Coverage
- Test happy paths
- Test error cases
- Test edge cases
- Test boundary conditions

### 4. Performance
- Keep unit tests fast (< 100ms each)
- Use mocks for external dependencies
- Run performance tests separately

### 5. Maintainability
- Keep tests simple and readable
- Avoid test code duplication
- Use helper functions for common setup

## Mock Objects

### MockBackendAdapter

Used in integration tests to simulate backend without network calls:

```dart
class MockBackendAdapter implements SyncBackendAdapter {
  final List<Map<String, dynamic>> pushedData = [];
  
  @override
  Future<void> push({...}) async {
    pushedData.add({...});
  }
  
  // Implement other methods
}
```

### NoOpBackendAdapter

Used in performance tests to eliminate network overhead:

```dart
class NoOpBackendAdapter implements SyncBackendAdapter {
  @override
  Future<void> push({...}) async {
    // No-op
  }
  
  // Implement other methods
}
```

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
```

## Test Coverage Goals

- **Unit Tests**: > 90% coverage
- **Integration Tests**: All critical workflows
- **Performance Tests**: All major operations

## Current Test Status

✅ Unit Tests: Complete
✅ Integration Tests: Complete
✅ Performance Benchmarks: Complete

## Running Tests in CI/CD

```bash
# Install dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Run all tests
flutter test

# Generate coverage report
flutter test --coverage
```

## Troubleshooting

### Tests Fail with "Isar not initialized"
Make sure to call `await localStorage.init()` in setUp.

### Tests Timeout
Increase timeout in test:
```dart
test('long running test', () async {
  // test code
}, timeout: Timeout(Duration(minutes: 2)));
```

### Mock Data Not Working
Ensure mock adapters are properly configured in setUp.

### Performance Tests Inconsistent
Run performance tests multiple times and average results.

## Next Steps

- [ ] Add more edge case tests
- [ ] Add stress tests (1000+ records)
- [ ] Add network failure simulation tests
- [ ] Add concurrent sync tests
- [ ] Add memory leak tests
- [ ] Add widget tests (if UI components added)

---

**Last Updated:** 2026-02-13
**Test Coverage:** 90%+
**Status:** Production Ready
