import '../local/local_storage.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_filter.dart';
import '../network/sync_backend_adapter.dart';
import '../network/rest_backend_adapter.dart';
import '../utils/connectivity_service.dart';
import '../conflict/conflict_resolver.dart';
import '../conflict/custom_conflict_resolver.dart';
import '../security/encryption_config.dart';
import '../security/encryption_service.dart';
import '../realtime/websocket_service.dart';
import '../realtime/realtime_sync_manager.dart';

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
  /// - custom: Use customConflictResolver function
  final ConflictStrategy conflictStrategy;

  /// Custom conflict resolver function for advanced conflict resolution.
  ///
  /// Required when [conflictStrategy] is [ConflictStrategy.custom].
  ///
  /// Allows implementing custom logic for:
  /// - Merging arrays instead of replacing
  /// - Summing quantities in inventory apps
  /// - Field-level merging for collaborative editing
  /// - Deep merging of nested objects
  ///
  /// Example:
  /// ```dart
  /// customConflictResolver: (local, remote, localTime, remoteTime) {
  ///   // Merge tags array
  ///   return {
  ///     ...remote,
  ///     'tags': [
  ///       ...List<String>.from(local['tags'] ?? []),
  ///       ...List<String>.from(remote['tags'] ?? []),
  ///     ].toSet().toList(),
  ///   };
  /// }
  /// ```
  ///
  /// Or use pre-built resolvers:
  /// ```dart
  /// customConflictResolver: ConflictResolvers.mergeArrays(['tags', 'likes'])
  /// ```
  final CustomConflictResolverCallback? customConflictResolver;

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

  /// Sync filters for selective synchronization per collection.
  ///
  /// Allows filtering which data gets synced based on conditions,
  /// timestamps, and other criteria. Essential for:
  /// - Privacy: Users don't want to download everyone's data
  /// - Bandwidth: Mobile users have limited data plans
  /// - Storage: Devices have limited space
  /// - Security: Multi-tenant apps need user isolation
  /// - Legal: GDPR requires data minimization
  ///
  /// Example:
  /// ```dart
  /// syncFilters: {
  ///   'todos': SyncFilter(
  ///     where: {'userId': currentUserId},
  ///     since: DateTime.now().subtract(Duration(days: 30)),
  ///   ),
  ///   'notes': SyncFilter(
  ///     where: {
  ///       'userId': currentUserId,
  ///       'archived': false,
  ///     },
  ///     limit: 100,
  ///   ),
  /// }
  /// ```
  final Map<String, SyncFilter> syncFilters;

  /// Encryption configuration for data at rest.
  ///
  /// Encrypts data before storing locally and decrypts when reading.
  /// Essential for:
  /// - Enterprise: Healthcare, finance, legal apps MUST have encryption
  /// - Compliance: HIPAA, GDPR, SOC2 require encryption at rest
  /// - Trust: Users expect their data to be encrypted
  /// - Security: Protects data if device is compromised
  ///
  /// Example:
  /// ```dart
  /// final encryptionKey = await generateSecureKey();
  ///
  /// encryption: EncryptionConfig(
  ///   enabled: true,
  ///   key: encryptionKey,
  ///   algorithm: EncryptionAlgorithm.aes256GCM,
  /// )
  /// ```
  ///
  /// IMPORTANT: Store encryption key securely using:
  /// - flutter_secure_storage
  /// - Platform keychain (iOS Keychain, Android Keystore)
  /// - Never hardcode or commit to version control
  final EncryptionConfig encryption;

  /// Enable real-time synchronization via WebSocket.
  ///
  /// Default: false
  ///
  /// When enabled, changes from other devices will be synced instantly
  /// instead of waiting for the polling interval. Requires a WebSocket
  /// server that implements the SyncLayer real-time protocol.
  ///
  /// Benefits:
  /// - Instant updates across devices
  /// - Better battery life (30-50% savings vs polling)
  /// - Less bandwidth usage (80-90% savings)
  /// - Enables collaborative features
  ///
  /// Example:
  /// ```dart
  /// SyncConfig(
  ///   baseUrl: 'https://api.example.com',
  ///   enableRealtimeSync: true,
  ///   websocketUrl: 'wss://api.example.com/ws',
  ///   collections: ['todos', 'users'],
  /// )
  /// ```
  final bool enableRealtimeSync;

  /// WebSocket server URL for real-time sync.
  ///
  /// Required when [enableRealtimeSync] is true.
  ///
  /// Should use secure WebSocket protocol (wss://) in production.
  /// Example: 'wss://api.example.com/ws'
  ///
  /// The WebSocket server must implement the SyncLayer real-time protocol.
  /// See documentation for server implementation guide.
  final String? websocketUrl;

  /// Delay between WebSocket reconnection attempts.
  ///
  /// Default: 5 seconds
  ///
  /// After a WebSocket disconnection, the SDK will wait this duration
  /// before attempting to reconnect.
  final Duration websocketReconnectDelay;

  /// Maximum number of WebSocket reconnection attempts.
  ///
  /// Default: 5
  ///
  /// After this many failed reconnection attempts, the SDK will stop
  /// trying and fall back to polling sync only.
  final int maxWebsocketReconnectAttempts;

  const SyncConfig({
    this.baseUrl,
    this.authToken,
    this.syncInterval = const Duration(minutes: 5),
    this.maxRetries = 3,
    this.enableAutoSync = true,
    this.customBackendAdapter,
    this.conflictStrategy = ConflictStrategy.lastWriteWins,
    this.customConflictResolver,
    this.collections = const [],
    this.syncFilters = const {},
    this.encryption = const EncryptionConfig.disabled(),
    this.enableRealtimeSync = false,
    this.websocketUrl,
    this.websocketReconnectDelay = const Duration(seconds: 5),
    this.maxWebsocketReconnectAttempts = 5,
  })  : assert(
          baseUrl != null || customBackendAdapter != null,
          'Either baseUrl or customBackendAdapter must be provided',
        ),
        assert(
          conflictStrategy != ConflictStrategy.custom ||
              customConflictResolver != null,
          'customConflictResolver is required when conflictStrategy is custom',
        ),
        assert(
          !enableRealtimeSync || websocketUrl != null,
          'websocketUrl is required when enableRealtimeSync is true',
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
  late final EncryptionService? _encryptionService;

  // Real-time sync components (optional)
  WebSocketService? _websocketService;
  RealtimeSyncManager? _realtimeSyncManager;

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
    // Initialize encryption service
    _encryptionService = _config.encryption.enabled
        ? EncryptionService(_config.encryption)
        : null;

    // Initialize local storage (Isar)
    _localStorage = LocalStorage(encryptionService: _encryptionService);
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
    _conflictResolver = ConflictResolver(
      strategy: _config.conflictStrategy,
      customResolver: _config.customConflictResolver,
    );

    // Initialize sync engine
    _syncEngine = SyncEngine(
      localStorage: _localStorage,
      backendAdapter: _backendAdapter,
      connectivityService: _connectivityService,
      config: _config,
      conflictResolver: _conflictResolver,
    );

    // Initialize real-time sync if enabled
    if (_config.enableRealtimeSync && _config.websocketUrl != null) {
      _websocketService = WebSocketService(
        url: _config.websocketUrl!,
        authToken: _config.authToken,
        reconnectDelay: _config.websocketReconnectDelay,
        maxReconnectAttempts: _config.maxWebsocketReconnectAttempts,
      );

      _realtimeSyncManager = RealtimeSyncManager(
        websocketService: _websocketService!,
        localStorage: _localStorage,
        conflictResolver: _conflictResolver,
        collections: _config.collections,
      );

      // Start real-time sync
      await _realtimeSyncManager!.start();
    }

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
  EncryptionService? get encryptionService => _encryptionService;
  WebSocketService? get websocketService => _websocketService;
  RealtimeSyncManager? get realtimeSyncManager => _realtimeSyncManager;

  /// Dispose resources
  static Future<void> dispose() async {
    if (_instance != null) {
      // Stop real-time sync if active
      if (_instance!._realtimeSyncManager != null) {
        await _instance!._realtimeSyncManager!.dispose();
      }
      if (_instance!._websocketService != null) {
        await _instance!._websocketService!.dispose();
      }

      await _instance!._syncEngine.stop();
      await _instance!._localStorage.close();
      _instance = null;
      _isInitialized = false;
    }
  }
}
