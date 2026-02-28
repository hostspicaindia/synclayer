import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:synclayer/synclayer.dart';

/// Enhanced test infrastructure with proper mocking and setup

/// Mock PathProviderPlatform for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String _basePath;

  MockPathProviderPlatform([String? basePath])
      : _basePath = basePath ?? Directory.systemTemp.path;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    final tempDir = Directory(
        '$_basePath/synclayer_test_docs_${DateTime.now().millisecondsSinceEpoch}');
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }
    return tempDir.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    final tempDir = Directory(
        '$_basePath/synclayer_test_temp_${DateTime.now().millisecondsSinceEpoch}');
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }
    return tempDir.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final tempDir = Directory(
        '$_basePath/synclayer_test_support_${DateTime.now().millisecondsSinceEpoch}');
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }
    return tempDir.path;
  }
}

/// Mock ConnectivityPlatform with controllable state
class MockConnectivityPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements ConnectivityPlatform {
  List<ConnectivityResult> _currentState = [ConnectivityResult.wifi];
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return _currentState;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  /// Simulate connectivity change
  void setConnectivity(List<ConnectivityResult> state) {
    _currentState = state;
    _controller.add(state);
  }

  /// Simulate going offline
  void goOffline() {
    setConnectivity([ConnectivityResult.none]);
  }

  /// Simulate going online
  void goOnline() {
    setConnectivity([ConnectivityResult.wifi]);
  }

  void dispose() {
    _controller.close();
  }
}

/// Mock backend adapter for testing
class MockBackendAdapter implements SyncBackendAdapter {
  // Shared static storage for multi-device simulation
  static final Map<String, List<SyncRecord>> _sharedCollections = {};
  static bool _sharedShouldFail = false;

  // Instance-specific tracking
  int _pushCallCount = 0;
  int _pullCallCount = 0;
  int _deleteCallCount = 0;
  Duration? _simulatedLatency;

  /// Simulate network latency
  void setLatency(Duration latency) {
    _simulatedLatency = latency;
  }

  /// Make operations fail
  void setShouldFail(bool shouldFail) {
    _sharedShouldFail = shouldFail;
  }

  /// Get call counts for verification
  int get pushCallCount => _pushCallCount;
  int get pullCallCount => _pullCallCount;
  int get deleteCallCount => _deleteCallCount;

  /// Get all records for a collection
  List<SyncRecord> getCollectionRecords(String collection) {
    return _sharedCollections[collection] ?? [];
  }

  /// Clear all data (static method to clear shared storage)
  static void clearSharedStorage() {
    _sharedCollections.clear();
    _sharedShouldFail = false;
  }

  /// Clear instance-specific data
  void clear() {
    _pushCallCount = 0;
    _pullCallCount = 0;
    _deleteCallCount = 0;
  }

  Future<void> _simulateLatency() async {
    if (_simulatedLatency != null) {
      await Future.delayed(_simulatedLatency!);
    }
  }

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    await _simulateLatency();
    _pushCallCount++;

    if (_sharedShouldFail) {
      throw Exception('Mock backend push failed');
    }

    final record = SyncRecord(
      recordId: recordId,
      data: data,
      updatedAt: timestamp,
      version: 1,
    );

    _sharedCollections.putIfAbsent(collection, () => []);
    final existing = _sharedCollections[collection]!
        .indexWhere((r) => r.recordId == recordId);

    if (existing >= 0) {
      _sharedCollections[collection]![existing] = record;
    } else {
      _sharedCollections[collection]!.add(record);
    }
  }

  @override
  Future<void> pushDelta({
    required String collection,
    required String recordId,
    required Map<String, dynamic> delta,
    required int baseVersion,
    required DateTime timestamp,
  }) async {
    await _simulateLatency();
    _pushCallCount++;

    if (_sharedShouldFail) {
      throw Exception('Mock backend pushDelta failed');
    }

    // Simulate delta merge
    _sharedCollections.putIfAbsent(collection, () => []);
    final existing = _sharedCollections[collection]!
        .firstWhere((r) => r.recordId == recordId,
            orElse: () => SyncRecord(
                  recordId: recordId,
                  data: {},
                  updatedAt: timestamp,
                  version: baseVersion,
                ));

    final merged = {...existing.data, ...delta};
    final record = SyncRecord(
      recordId: recordId,
      data: merged,
      updatedAt: timestamp,
      version: baseVersion + 1,
    );

    final index = _sharedCollections[collection]!
        .indexWhere((r) => r.recordId == recordId);
    if (index >= 0) {
      _sharedCollections[collection]![index] = record;
    } else {
      _sharedCollections[collection]!.add(record);
    }
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
    SyncFilter? filter,
  }) async {
    await _simulateLatency();
    _pullCallCount++;

    if (_sharedShouldFail) {
      throw Exception('Mock backend pull failed');
    }

    var records = _sharedCollections[collection] ?? [];

    // Apply since filter
    if (since != null) {
      records = records.where((r) => r.updatedAt.isAfter(since)).toList();
    }

    // Apply sync filter
    if (filter != null) {
      records = records.where((r) {
        return filter.matches(r.data, r.updatedAt);
      }).toList();

      // Apply field filtering
      records = records.map((r) {
        final filteredData = filter.applyFieldFilter(r.data);
        return SyncRecord(
          recordId: r.recordId,
          data: filteredData,
          updatedAt: r.updatedAt,
          version: r.version,
        );
      }).toList();
    }

    // Apply offset
    if (offset != null && offset > 0) {
      records = records.skip(offset).toList();
    }

    // Apply limit
    if (limit != null && limit > 0) {
      records = records.take(limit).toList();
    }

    return records;
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    await _simulateLatency();
    _deleteCallCount++;

    if (_sharedShouldFail) {
      throw Exception('Mock backend delete failed');
    }

    _sharedCollections[collection]?.removeWhere((r) => r.recordId == recordId);
  }

  @override
  void updateAuthToken(String token) {
    // Mock implementation
  }
}

/// Test environment setup helper
class TestEnvironment {
  late MockPathProviderPlatform pathProvider;
  late MockConnectivityPlatform connectivity;
  late MockBackendAdapter backend;
  late Directory testDir;

  Future<void> setUp() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Create unique test directory
    testDir = Directory.systemTemp.createTempSync('synclayer_test_');

    // Setup mocks
    pathProvider = MockPathProviderPlatform(testDir.path);
    connectivity = MockConnectivityPlatform();
    backend = MockBackendAdapter();

    PathProviderPlatform.instance = pathProvider;
    ConnectivityPlatform.instance = connectivity;

    // Initialize Isar
    try {
      await Isar.initializeIsarCore(download: false);
    } catch (e) {
      // Already initialized
    }
  }

  Future<void> tearDown() async {
    try {
      await SyncLayer.dispose();
    } catch (e) {
      // May not be initialized
    }

    connectivity.dispose();
    backend.clear();

    // Clean up test directory
    if (testDir.existsSync()) {
      try {
        testDir.deleteSync(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  /// Initialize SyncLayer with mock backend
  Future<void> initSyncLayer({
    Duration? syncInterval,
    bool enableAutoSync = false,
    ConflictStrategy conflictStrategy = ConflictStrategy.lastWriteWins,
    List<String> collections = const ['test'],
    Map<String, SyncFilter>? syncFilters,
  }) async {
    await SyncLayer.init(
      SyncConfig(
        customBackendAdapter: backend,
        syncInterval: syncInterval ?? const Duration(minutes: 5),
        enableAutoSync: enableAutoSync,
        conflictStrategy: conflictStrategy,
        collections: collections,
        syncFilters: syncFilters ?? {},
      ),
    );
  }
}

/// Helper to wait for async operations
Future<void> waitForSync({Duration? timeout}) async {
  await Future.delayed(timeout ?? const Duration(milliseconds: 100));
}

/// Helper to create test data
Map<String, dynamic> createTestData({
  String? text,
  int? number,
  bool? flag,
  List<String>? tags,
}) {
  return {
    'text': text ?? 'Test data',
    'number': number ?? 42,
    'flag': flag ?? true,
    'tags': tags ?? ['test', 'mock'],
    'timestamp': DateTime.now().toIso8601String(),
  };
}
