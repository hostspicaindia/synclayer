import '../local/local_storage.dart';
import '../sync/sync_engine.dart';
import '../network/sync_backend_adapter.dart';
import '../network/rest_backend_adapter.dart';
import '../utils/connectivity_service.dart';
import '../conflict/conflict_resolver.dart';

/// Configuration for SyncLayer initialization
class SyncConfig {
  final String baseUrl;
  final String? authToken;
  final Duration syncInterval;
  final int maxRetries;
  final bool enableAutoSync;
  final SyncBackendAdapter? customBackendAdapter;
  final ConflictStrategy conflictStrategy;
  final List<String> collections;

  const SyncConfig({
    required this.baseUrl,
    this.authToken,
    this.syncInterval = const Duration(minutes: 5),
    this.maxRetries = 3,
    this.enableAutoSync = true,
    this.customBackendAdapter,
    this.conflictStrategy = ConflictStrategy.lastWriteWins,
    this.collections = const [],
  });
}

/// Core initialization and lifecycle manager for SyncLayer
class SyncLayerCore {
  static SyncLayerCore? _instance;
  static bool _isInitialized = false;

  late final LocalStorage _localStorage;
  late final SyncBackendAdapter _backendAdapter;
  late final ConnectivityService _connectivityService;
  late final ConflictResolver _conflictResolver;
  late final SyncEngine _syncEngine;
  late final SyncConfig _config;

  SyncLayerCore._();

  static SyncLayerCore get instance {
    if (_instance == null || !_isInitialized) {
      throw StateError(
        'SyncLayer not initialized. Call SyncLayer.init() first.',
      );
    }
    return _instance!;
  }

  /// Initialize SyncLayer with configuration
  static Future<void> init(SyncConfig config) async {
    if (_isInitialized) {
      throw StateError('SyncLayer already initialized');
    }

    _instance = SyncLayerCore._();
    _instance!._config = config;

    await _instance!._initialize();
    _isInitialized = true;
  }

  Future<void> _initialize() async {
    // Initialize local storage (Isar)
    _localStorage = LocalStorage();
    await _localStorage.init();

    // Initialize backend adapter (use custom or default REST)
    _backendAdapter = _config.customBackendAdapter ??
        RestBackendAdapter(
          baseUrl: _config.baseUrl,
          authToken: _config.authToken,
        );

    // Initialize connectivity service
    _connectivityService = ConnectivityService();
    await _connectivityService.init();

    // Initialize conflict resolver
    _conflictResolver = ConflictResolver(strategy: _config.conflictStrategy);

    // Initialize sync engine
    _syncEngine = SyncEngine(
      localStorage: _localStorage,
      backendAdapter: _backendAdapter,
      connectivityService: _connectivityService,
      config: _config,
      conflictResolver: _conflictResolver,
    );

    if (_config.enableAutoSync) {
      await _syncEngine.start();
    }
  }

  LocalStorage get localStorage => _localStorage;
  SyncBackendAdapter get backendAdapter => _backendAdapter;
  SyncEngine get syncEngine => _syncEngine;
  ConnectivityService get connectivityService => _connectivityService;
  ConflictResolver get conflictResolver => _conflictResolver;
  SyncConfig get config => _config;

  /// Dispose resources
  static Future<void> dispose() async {
    if (_instance != null) {
      await _instance!._syncEngine.stop();
      await _instance!._localStorage.close();
      _instance = null;
      _isInitialized = false;
    }
  }
}
