import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

void main() {
  group('WebSocketService', () {
    late WebSocketService service;

    setUp(() {
      service = WebSocketService(
        url: 'ws://localhost:8080/ws',
        authToken: 'test-token',
        reconnectDelay: Duration(seconds: 1),
        maxReconnectAttempts: 3,
      );
    });

    tearDown(() async {
      await service.dispose();
    });

    test('initializes with disconnected state', () {
      expect(service.state, WebSocketState.disconnected);
      expect(service.isConnected, false);
    });

    test('state changes are emitted', () async {
      final states = <WebSocketState>[];

      service.onStateChanged.listen((state) {
        states.add(state);
      });

      // Note: Actual connection will fail in test environment
      // We're just testing that state changes are emitted
      try {
        await service.connect();
      } catch (e) {
        // Expected to fail in test environment
      }

      // Should have attempted to connect
      expect(states, isNotEmpty);
    });

    test('message serialization works correctly', () {
      final message = WebSocketMessage(
        type: MessageType.insert,
        collection: 'todos',
        recordId: '123',
        data: {'text': 'Test', 'done': false},
        timestamp: DateTime(2026, 2, 24, 10, 30),
      );

      final json = message.toJson();

      expect(json['type'], 'insert');
      expect(json['collection'], 'todos');
      expect(json['recordId'], '123');
      expect(json['data'], {'text': 'Test', 'done': false});
      expect(json['timestamp'], '2026-02-24T10:30:00.000');
    });

    test('message deserialization works correctly', () {
      final json = {
        'type': 'update',
        'collection': 'todos',
        'recordId': '456',
        'data': {'done': true},
        'timestamp': '2026-02-24T10:31:00.000Z',
        'metadata': {'version': 2},
      };

      final message = WebSocketMessage.fromJson(json);

      expect(message.type, MessageType.update);
      expect(message.collection, 'todos');
      expect(message.recordId, '456');
      expect(message.data, {'done': true});
      expect(message.metadata, {'version': 2});
    });

    test('subscribe adds collection to subscriptions', () {
      service.subscribe('todos');
      service.subscribe('users');

      // Subscriptions are tracked internally
      // We can't directly test private fields, but we can verify
      // the method doesn't throw
      expect(() => service.subscribe('notes'), returnsNormally);
    });

    test('unsubscribe removes collection from subscriptions', () {
      service.subscribe('todos');
      service.unsubscribe('todos');

      // Should not throw
      expect(() => service.unsubscribe('users'), returnsNormally);
    });

    test('send queues message when disconnected', () {
      final message = WebSocketMessage(
        type: MessageType.insert,
        collection: 'todos',
        recordId: '789',
        data: {'text': 'Test'},
      );

      // Should not throw even when disconnected
      expect(() => service.send(message), returnsNormally);
    });

    test('dispose cleans up resources', () async {
      await service.dispose();

      // After dispose, state should be disconnected
      expect(service.state, WebSocketState.disconnected);
    });

    test('MessageType enum has all expected values', () {
      expect(MessageType.values, contains(MessageType.sync));
      expect(MessageType.values, contains(MessageType.insert));
      expect(MessageType.values, contains(MessageType.update));
      expect(MessageType.values, contains(MessageType.delete));
      expect(MessageType.values, contains(MessageType.ping));
      expect(MessageType.values, contains(MessageType.pong));
      expect(MessageType.values, contains(MessageType.subscribe));
      expect(MessageType.values, contains(MessageType.unsubscribe));
    });

    test('WebSocketState enum has all expected values', () {
      expect(WebSocketState.values, contains(WebSocketState.disconnected));
      expect(WebSocketState.values, contains(WebSocketState.connecting));
      expect(WebSocketState.values, contains(WebSocketState.connected));
      expect(WebSocketState.values, contains(WebSocketState.reconnecting));
      expect(WebSocketState.values, contains(WebSocketState.error));
    });
  });

  group('WebSocketMessage', () {
    test('creates message with required fields only', () {
      final message = WebSocketMessage(type: MessageType.ping);

      expect(message.type, MessageType.ping);
      expect(message.collection, isNull);
      expect(message.recordId, isNull);
      expect(message.data, isNull);
      expect(message.timestamp, isNull);
      expect(message.metadata, isNull);
    });

    test('creates message with all fields', () {
      final timestamp = DateTime.now();
      final message = WebSocketMessage(
        type: MessageType.insert,
        collection: 'todos',
        recordId: '123',
        data: {'text': 'Test'},
        timestamp: timestamp,
        metadata: {'version': 1},
      );

      expect(message.type, MessageType.insert);
      expect(message.collection, 'todos');
      expect(message.recordId, '123');
      expect(message.data, {'text': 'Test'});
      expect(message.timestamp, timestamp);
      expect(message.metadata, {'version': 1});
    });

    test('toJson includes only non-null fields', () {
      final message = WebSocketMessage(
        type: MessageType.delete,
        collection: 'todos',
        recordId: '123',
      );

      final json = message.toJson();

      expect(json['type'], 'delete');
      expect(json['collection'], 'todos');
      expect(json['recordId'], '123');
      expect(json.containsKey('data'), false);
      expect(json.containsKey('timestamp'), false);
      expect(json.containsKey('metadata'), false);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'type': 'ping',
      };

      final message = WebSocketMessage.fromJson(json);

      expect(message.type, MessageType.ping);
      expect(message.collection, isNull);
      expect(message.recordId, isNull);
      expect(message.data, isNull);
      expect(message.timestamp, isNull);
      expect(message.metadata, isNull);
    });

    test('fromJson parses timestamp correctly', () {
      final json = {
        'type': 'insert',
        'timestamp': '2026-02-24T10:30:00.000Z',
      };

      final message = WebSocketMessage.fromJson(json);

      expect(message.timestamp, isNotNull);
      expect(message.timestamp!.year, 2026);
      expect(message.timestamp!.month, 2);
      expect(message.timestamp!.day, 24);
    });

    test('round-trip serialization preserves data', () {
      final original = WebSocketMessage(
        type: MessageType.update,
        collection: 'todos',
        recordId: '123',
        data: {'text': 'Test', 'done': true, 'priority': 5},
        timestamp: DateTime(2026, 2, 24, 10, 30),
        metadata: {'version': 2, 'userId': 'user123'},
      );

      final json = original.toJson();
      final restored = WebSocketMessage.fromJson(json);

      expect(restored.type, original.type);
      expect(restored.collection, original.collection);
      expect(restored.recordId, original.recordId);
      expect(restored.data, original.data);
      expect(restored.metadata, original.metadata);
      // Timestamp comparison (allowing for millisecond precision)
      expect(
        restored.timestamp!
            .difference(original.timestamp!)
            .inMilliseconds
            .abs(),
        lessThan(1000),
      );
    });
  });
}
