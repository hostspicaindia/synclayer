import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/logger.dart';

/// WebSocket connection states
enum WebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket message types
enum MessageType {
  sync,
  insert,
  update,
  delete,
  ping,
  pong,
  subscribe,
  unsubscribe,
}

/// WebSocket message structure
class WebSocketMessage {
  final MessageType type;
  final String? collection;
  final String? recordId;
  final Map<String, dynamic>? data;
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;

  WebSocketMessage({
    required this.type,
    this.collection,
    this.recordId,
    this.data,
    this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (collection != null) 'collection': collection,
        if (recordId != null) 'recordId': recordId,
        if (data != null) 'data': data,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.sync,
      ),
      collection: json['collection'],
      recordId: json['recordId'],
      data: json['data'],
      timestamp:
          json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      metadata: json['metadata'],
    );
  }
}

/// WebSocket service for real-time sync
class WebSocketService {
  final String url;
  final String? authToken;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;

  WebSocketChannel? _channel;
  WebSocketState _state = WebSocketState.disconnected;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  final _logger = SyncLogger.instance;

  // Stream controllers
  final _stateController = StreamController<WebSocketState>.broadcast();
  final _messageController = StreamController<WebSocketMessage>.broadcast();

  WebSocketService({
    required this.url,
    this.authToken,
    this.reconnectDelay = const Duration(seconds: 5),
    this.maxReconnectAttempts = 5,
  });

  /// Current connection state
  WebSocketState get state => _state;

  /// Stream of connection state changes
  Stream<WebSocketState> get onStateChanged => _stateController.stream;

  /// Stream of incoming messages
  Stream<WebSocketMessage> get onMessage => _messageController.stream;

  /// Check if connected
  bool get isConnected => _state == WebSocketState.connected;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_state == WebSocketState.connected ||
        _state == WebSocketState.connecting) {
      return;
    }

    _updateState(WebSocketState.connecting);
    _logger.info('WebSocket connecting to: $url');

    try {
      // Build WebSocket URL with auth token if provided
      final wsUrl = authToken != null ? '$url?token=$authToken' : url;

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _updateState(WebSocketState.connected);
      _reconnectAttempts = 0;
      _logger.info('WebSocket connected');

      // Start ping timer to keep connection alive
      _startPingTimer();
    } catch (e, stackTrace) {
      _logger.error('WebSocket connection error', e, stackTrace);
      _updateState(WebSocketState.error);
      _scheduleReconnect();
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _logger.info('WebSocket disconnecting');
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _updateState(WebSocketState.disconnected);
  }

  /// Send message to server
  void send(WebSocketMessage message) {
    if (!isConnected) {
      _logger.warning('Cannot send message - not connected');
      return;
    }

    try {
      final json = jsonEncode(message.toJson());
      _channel!.sink.add(json);
      _logger.debug('WebSocket sent: ${message.type.name}');
    } catch (e, stackTrace) {
      _logger.error('WebSocket send error', e, stackTrace);
    }
  }

  /// Subscribe to collection changes
  void subscribe(String collection) {
    send(WebSocketMessage(
      type: MessageType.subscribe,
      collection: collection,
    ));
  }

  /// Unsubscribe from collection changes
  void unsubscribe(String collection) {
    send(WebSocketMessage(
      type: MessageType.unsubscribe,
      collection: collection,
    ));
  }

  /// Handle incoming messages
  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = WebSocketMessage.fromJson(json);

      _logger.debug('WebSocket received: ${message.type.name}');

      // Handle pong response
      if (message.type == MessageType.pong) {
        return;
      }

      _messageController.add(message);
    } catch (e, stackTrace) {
      _logger.error('WebSocket message parse error', e, stackTrace);
    }
  }

  /// Handle connection errors
  void _onError(Object error) {
    _logger.error('WebSocket error', error);
    _updateState(WebSocketState.error);
    _scheduleReconnect();
  }

  /// Handle connection close
  void _onDone() {
    _logger.info('WebSocket connection closed');
    _updateState(WebSocketState.disconnected);
    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _logger.error(
          'WebSocket max reconnect attempts reached ($maxReconnectAttempts)');
      _updateState(WebSocketState.error);
      return;
    }

    _reconnectAttempts++;
    _updateState(WebSocketState.reconnecting);

    _logger.info(
        'WebSocket reconnecting in ${reconnectDelay.inSeconds}s (attempt $_reconnectAttempts/$maxReconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      connect();
    });
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected) {
        send(WebSocketMessage(type: MessageType.ping));
      }
    });
  }

  /// Update connection state
  void _updateState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _messageController.close();
  }
}
