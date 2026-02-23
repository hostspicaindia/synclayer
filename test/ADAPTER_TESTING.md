## Adapter Testing Guide

This document explains how to test the database adapters in SyncLayer.

## Test Structure

```
test/
├── adapters_test_suite.dart          # Main test runner
├── unit/
│   └── adapters/
│       ├── adapter_interface_test.dart    # Interface contract tests
│       ├── mock_adapter_test.dart         # Mock adapter behavior tests
│       └── adapter_validation_test.dart   # Data validation tests
└── integration/
    └── adapter_integration_test.dart      # Integration tests
```

## Running Tests

### Run All Adapter Tests
```bash
flutter test test/adapters_test_suite.dart
```

### Run Specific Test Files
```bash
# Interface tests
flutter test test/unit/adapters/adapter_interface_test.dart

# Mock adapter tests
flutter test test/unit/adapters/mock_adapter_test.dart

# Validation tests
flutter test test/unit/adapters/adapter_validation_test.dart

# Integration tests
flutter test test/integration/adapter_integration_test.dart
```

### Run All Tests
```bash
flutter test
```

## Test Coverage

### 1. Interface Tests (`adapter_interface_test.dart`)
Tests the `SyncBackendAdapter` interface contract:
- ✅ SyncRecord construction
- ✅ Complex data structures
- ✅ Timestamp handling
- ✅ Version numbers
- ✅ Method signatures
- ✅ Data validation

### 2. Mock Adapter Tests (`mock_adapter_test.dart`)
Tests adapter behavior using a mock implementation:
- ✅ Push operations
- ✅ Pull operations
- ✅ Delete operations
- ✅ Auth token updates
- ✅ Collection filtering
- ✅ Timestamp filtering
- ✅ CRUD cycles
- ✅ Concurrent operations
- ✅ Data integrity

### 3. Validation Tests (`adapter_validation_test.dart`)
Tests data validation and serialization:
- ✅ SQL schema requirements
- ✅ NoSQL document structure
- ✅ JSON serialization
- ✅ Timestamp conversion
- ✅ Connection strings
- ✅ Error handling
- ✅ Data integrity
- ✅ Large payloads

### 4. Integration Tests (`adapter_integration_test.dart`)
Tests adapter integration with sync engine:
- ✅ Sync engine compatibility
- ✅ Batch operations
- ✅ Performance
- ✅ Adapter interchangeability

## Test Results

Expected output when all tests pass:

```
00:01 +1: Adapter Test Suite Interface Tests SyncBackendAdapter Interface SyncRecord should be constructible with required fields
00:01 +2: Adapter Test Suite Interface Tests SyncBackendAdapter Interface SyncRecord should handle complex data structures
...
00:05 +50: All tests passed!
```

## Why Mock Tests?

We use mock-based tests instead of requiring actual database connections because:

1. **No Setup Required**: Tests run without installing databases
2. **Fast Execution**: No network latency or database overhead
3. **Consistent Results**: No external dependencies
4. **CI/CD Friendly**: Works in any environment
5. **Focus on Logic**: Tests adapter behavior, not database specifics

## Testing Real Adapters

To test with real databases (optional):

### PostgreSQL Example
```dart
test('PostgreSQL adapter integration', () async {
  final conn = await Connection.open(
    Endpoint(host: 'localhost', database: 'test_db'),
  );
  
  final adapter = PostgresAdapter(connection: conn);
  
  await adapter.push(
    collection: 'test',
    recordId: 'test-1',
    data: {'test': 'data'},
    timestamp: DateTime.now(),
  );
  
  final records = await adapter.pull(collection: 'test');
  expect(records.length, greaterThan(0));
  
  await conn.close();
}, skip: 'Requires PostgreSQL running');
```

## Continuous Integration

These tests are designed to run in CI/CD pipelines:

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test test/adapters_test_suite.dart
```

## Test Metrics

Current test coverage:
- **Interface Tests**: 15 tests
- **Mock Adapter Tests**: 25 tests
- **Validation Tests**: 10 tests
- **Integration Tests**: 5 tests
- **Total**: 55+ tests

## Adding New Tests

When adding a new adapter, add tests for:

1. **Interface Compliance**: Verify it implements `SyncBackendAdapter`
2. **Data Serialization**: Test JSON encoding/decoding
3. **Error Handling**: Test connection failures, timeouts
4. **Edge Cases**: Empty data, large payloads, special characters

Example:
```dart
test('NewAdapter should implement interface', () {
  final adapter = NewAdapter(...);
  expect(adapter, isA<SyncBackendAdapter>());
});
```

## Troubleshooting

### Tests Fail with "Package not found"
This is expected for optional adapter packages. The tests use mocks and don't require actual database packages.

### Tests Timeout
Increase timeout in test:
```dart
test('slow operation', () async {
  // test code
}, timeout: Timeout(Duration(seconds: 30)));
```

### Import Errors
Make sure you're running from project root:
```bash
cd /path/to/synclayer
flutter test
```

## Best Practices

1. **Keep tests fast**: Use mocks, avoid real databases
2. **Test behavior, not implementation**: Focus on what adapters do
3. **Use descriptive names**: Make test purpose clear
4. **Test edge cases**: Empty data, nulls, large payloads
5. **Clean up resources**: Close connections, clear state

## Next Steps

- Run the test suite: `flutter test test/adapters_test_suite.dart`
- Check coverage: `flutter test --coverage`
- Add database-specific tests as needed
- Update this document when adding new tests
