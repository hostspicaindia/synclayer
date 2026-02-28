import 'package:flutter_test/flutter_test.dart';

/// Comprehensive test runner for SyncLayer SDK
///
/// This file imports and runs all test suites to ensure complete coverage.
/// Run with: flutter test test/run_all_tests.dart

// Unit tests
import 'unit/sync_engine_test.dart' as sync_engine_test;
import 'unit/local_storage_test.dart' as local_storage_test;
import 'unit/queue_manager_test.dart' as queue_manager_test;
import 'unit/conflict_resolver_test.dart' as conflict_resolver_test;

// Integration tests
import 'integration/full_sync_cycle_test.dart' as full_sync_cycle_test;
import 'integration/sync_flow_test.dart' as sync_flow_test;
import 'integration/adapter_integration_test.dart' as adapter_integration_test;

// Stress tests
import 'stress/stress_test.dart' as stress_test;

// Feature tests
import 'query_test.dart' as query_test;
import 'delta_sync_test.dart' as delta_sync_test;
import 'encryption_test.dart' as encryption_test;
import 'sync_filter_test.dart' as sync_filter_test;
import 'custom_conflict_resolver_test.dart' as custom_conflict_resolver_test;

// Comprehensive tests
import 'comprehensive/01_initialization_test.dart' as init_test;
import 'comprehensive/02_crud_operations_test.dart' as crud_test;
import 'comprehensive/03_batch_operations_test.dart' as batch_test;
import 'comprehensive/04_query_operations_test.dart' as query_ops_test;

void main() {
  group('SyncLayer Test Suite', () {
    group('Unit Tests', () {
      sync_engine_test.main();
      local_storage_test.main();
      queue_manager_test.main();
      conflict_resolver_test.main();
    });

    group('Integration Tests', () {
      full_sync_cycle_test.main();
      sync_flow_test.main();
      adapter_integration_test.main();
    });

    group('Feature Tests', () {
      query_test.main();
      delta_sync_test.main();
      encryption_test.main();
      sync_filter_test.main();
      custom_conflict_resolver_test.main();
    });

    group('Comprehensive Tests', () {
      init_test.main();
      crud_test.main();
      batch_test.main();
      query_ops_test.main();
    });

    group('Stress Tests', () {
      stress_test.main();
    });
  });
}
