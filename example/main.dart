import 'package:flutter/material.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SyncLayer
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      authToken: 'your-auth-token',
      syncInterval: Duration(minutes: 5),
      enableAutoSync: true,
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SyncLayer Demo',
      home: MessagesScreen(),
    );
  }
}

class MessagesScreen extends StatefulWidget {
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () async {
              await SyncLayer.syncNow();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sync triggered')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SyncLayer.collection('messages').watch(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Text(message['text'] ?? ''),
                      subtitle: Text(message['timestamp'] ?? ''),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          // Delete is queued and synced automatically
                          await SyncLayer.collection('messages')
                              .delete(message['id']);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (_textController.text.isEmpty) return;

                    // Save locally first, sync happens automatically
                    final id = await SyncLayer.collection('messages').save({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'text': _textController.text,
                      'timestamp': DateTime.now().toIso8601String(),
                      'userId': 'user123',
                    });

                    _textController.clear();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Message saved: $id')),
                    );
                  },
                  child: Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
