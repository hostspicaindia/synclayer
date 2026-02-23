import 'package:flutter_test/flutter_test.dart';

// Import all adapter tests
import 'unit/adapters/adapter_interface_test.dart' as interface_test;
import 'unit/adapters/mock_adapter_test.dart' as mock_test;
import 'unit/adapters/adapter_validation_test.dart' as validation_test;
import 'integration/adapter_integration_test.dart' as integration_test;

/// Comprehensive test suite for all database adapters
///
/// Run with: flutter test test/adapters_test_suite.dart
void main() {
  group('Adapter Test Suite', () {
    group('Interface Tests', () {
      interface_test.main();
    });

    group('Mock Adapter Tests', () {
      mock_test.main();
    });

    group('Validation Tests', () {
      validation_test.main();
    });

    group('Integration Tests', () {
      integration_test.main();
    });
  });
}
