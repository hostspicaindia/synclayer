import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'unit/local_storage_test.dart' as local_storage_test;
import 'unit/conflict_resolver_test.dart' as conflict_resolver_test;
import 'unit/queue_manager_test.dart' as queue_manager_test;
import 'integration/sync_flow_test.dart' as sync_flow_test;
import 'performance/benchmark_test.dart' as benchmark_test;

void main() {
  group('Unit Tests', () {
    local_storage_test.main();
    conflict_resolver_test.main();
    queue_manager_test.main();
  });

  group('Integration Tests', () {
    sync_flow_test.main();
  });

  group('Performance Tests', () {
    benchmark_test.main();
  });
}
