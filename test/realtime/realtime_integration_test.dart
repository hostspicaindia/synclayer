import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

void main() {
  group('Real-Time Sync Integration', () {
    test('SyncConfig accepts real-time parameters', () {
      final config = SyncConfig(
        baseUrl: 'https://api.example.com',
        enableRealtimeSync: true,
        websocketUrl: 'wss://api.example.com/ws',
        websocketReconnectDelay: Duration(seconds: 3),
        maxWebsocketReconnectAttempts: 10,
        collections: ['todos'],
      );

      expect(config.enableRealtimeSync, true);
      expect(config.websocketUrl, 'wss://api.example.com/ws');
      expect(config.websocketReconnectDelay, Duration(seconds: 3));
      expect(config.maxWebsocketReconnectAttempts, 10);
    });

    test('SyncConfig requires websocketUrl when enableRealtimeSync is true',
        () {
      expect(
        () => SyncConfig(
          baseUrl: 'https://api.example.com',
          enableRealtimeSync: true,
          // Missing websocketUrl
          collections: ['todos'],
        ),
        throwsAssertionError,
      );
    });

    test('SyncConfig allows enableRealtimeSync false without websocketUrl', () {
      final config = SyncConfig(
        baseUrl: 'https://api.example.com',
        enableRealtimeSync: false,
        collections: ['todos'],
      );

      expect(config.enableRealtimeSync, false);
      expect(config.websocketUrl, null);
    });

    test('WebSocketMessage types are exported', () {
      // Verify MessageType enum is accessible
      expect(MessageType.insert, isNotNull);
      expect(MessageType.update, isNotNull);
      expect(MessageType.delete, isNotNull);
      expect(MessageType.sync, isNotNull);
      expect(MessageType.subscribe, isNotNull);
      expect(MessageType.unsubscribe, isNotNull);
      expect(MessageType.ping, isNotNull);
      expect(MessageType.pong, isNotNull);
    });

    test('WebSocketState enum is exported', () {
      // Verify WebSocketState enum is accessible
      expect(WebSocketState.disconnected, isNotNull);
      expect(WebSocketState.connecting, isNotNull);
      expect(WebSocketState.connected, isNotNull);
      expect(WebSocketState.reconnecting, isNotNull);
      expect(WebSocketState.error, isNotNull);
    });

    test('SyncEventType includes real-time events', () {
      // Verify real-time event types are accessible
      expect(SyncEventType.realtimeConnected, isNotNull);
      expect(SyncEventType.realtimeDisconnected, isNotNull);
      expect(SyncEventType.realtimeInsert, isNotNull);
      expect(SyncEventType.realtimeUpdate, isNotNull);
      expect(SyncEventType.realtimeDelete, isNotNull);
      expect(SyncEventType.realtimeSync, isNotNull);
    });
  });
}
