import '../local/local_storage.dart';
import '../sync/sync_engine.dart';
import '../network/sync_backend_adapter.dart';
import '../network/rest_backend_adapter.dart';
import '../utils/connectivity_service.dart';
import '../conflict/conflict_resolver.dart';

/// Configuration for SyncLayer initialization.
///
/// This class contains all the settings needed to configure SyncLayer's
/// behavior, including backend connection, sync intervals, conflict
/// resolution strategy, and which collections to sync.
///
/// Example:
/// ```dart
/// final config = SyncConfig(
///   baseUrl: 'https://api.example.com',
///   authToken: 'your-auth-token',
///   syncInterval: Duration(minutes: 5),
///   maxRetries: 3,
///   enableAutoSync: true,
///   collections: ['todos', 'users', 'notes'],
///   conflictStrategy: ConflictStrategy.lastWriteWins,
/// );
///
/// await SyncLayer.init(config);
/// ```
class SyncConfig {
  /// The base URL of your backend API.
  ///
  /// This should be the root URL without trailing slash.
  /// Example: 'https://api.example.com'
  ///
  /// Required unless [customBackendAdapter] is provided.
  final String? baseUrl;

  /// Optional authentication token for backend requests.
  ///
  /// If provided, this token will be included in the Authorization
  /// header of all HTTP requests to the backend.
  final String? authToken;

  /// How often to automatically sync with the backend.
  ///
  /// Default: 5 minutes
  ///
  /// Set to a shorter duration for more real-time sync, or longer
  /// to reduce network usage and battery consumption.
  final Duration syncInterval;

  /// Maximum number of retry attempts for failed sync operations.
  ///
  /// Default: 3
  ///
  /// After this many failures, the operation will be marked as failed
  /// and won't be retried until connectivity is restored.
  final int maxRetries;

  /// Whether to enable automatic background synchronization.
  ///
  /// Default: true
  ///
  /// If false, sync will only happen when [SyncLayer.syncNow()] is
  /// called manually.
  final bool enableAutoSync;

  /// Optional custom backend adapter for non-REST backends.
  ///
  /// Provide your own implementation of [SyncBackendAdapter] to
  /// integrate with Firebase, Supabase, GraphQL, or other backends.
  ///
  /// If null, the default REST adapter will be used.
  final SyncBackendAdapter? customBackendAdapter;

  /// Strategy for resolving conflicts when the same document is
  /// modified on multiple devices.
  ///
  /// Default: [ConflictStrategy.lastWriteWins]
  ///
  /// Available strategies:
  /// - lastWriteWins: Most recent change wins (based on timestamp)
  /// - serverWins: Server version always wins
  /// - clientWins: Client version always wins
  final ConflictStrategy conflictStrategy;

  /// List of collection names to sync with the backend.
  ///
  /// Default: empty list (will only sync collections with local data)
  ///
  /// **Important:** For pull sync to work on fresh devices, you must
  /// specify which collections to sync. Otherwise, pull sync will only
  /// check collections that already have local data.
  ///
  /// Example:
  /// ```dart
  /// collections: ['todos', 'users', 'notes']
  /// ```
  final List<String> collections;

  const SyncConfig({
    this.baseUrl,
    this.authToken,
    this.syncInterval = const Duration(minutes: 5),
    this.maxRetries = 3,
    this.enableAutoSync = true,
    this.customBackendAdapter,
    this.conflictStrategy = ConflictStrategy.lastWriteWins,
    this.collections = const [],
  }) : assert(
          baseUrl != null || customBackendAdapter != null,
          'Either baseUrl or customBackendAdapter must be provided',
        );
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
          baseUrl: _config.baseUrl!,
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
