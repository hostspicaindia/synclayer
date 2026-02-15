/// Example: Using SyncLayer with Supabase
///
/// This example shows how to integrate SyncLayer with Supabase
/// for automatic offline-first sync with PostgreSQL.
///
/// Setup:
/// 1. Add dependencies to pubspec.yaml:
///    - supabase_flutter: ^2.9.0
///    - synclayer: ^0.1.0
///
/// 2. Create a Supabase project at https://supabase.com
///
/// 3. Create a table in Supabase SQL Editor:
///    ```sql
///    CREATE TABLE todos (
///      record_id TEXT PRIMARY KEY,
///      data JSONB NOT NULL,
///      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
///      version INTEGER NOT NULL DEFAULT 1
///    );
///    CREATE INDEX idx_todos_updated_at ON todos(updated_at);
///    ```
///
/// 4. Run this example

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  // Initialize SyncLayer with Supabase adapter
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'YOUR_SUPABASE_URL', // Not used
      customBackendAdapter: SupabaseAdapter(
        client: Supabase.instance.client,
      ),
      collections: ['todos'],
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
      title: 'SyncLayer + Supabase',
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todos (Supabase)'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () async {
              await SyncLayer.syncNow();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Synced with Supabase')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter todo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (_textController.text.isNotEmpty) {
                      await SyncLayer.collection('todos').save({
                        'text': _textController.text,
                        'completed': false,
                        'createdAt': DateTime.now().toIso8601String(),
                      });
                      _textController.clear();
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SyncLayer.collection('todos').watch(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final todos = snapshot.data!;

                if (todos.isEmpty) {
                  return Center(
                    child: Text('No todos yet. Add one above!'),
                  );
                }

                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return ListTile(
                      leading: Checkbox(
                        value: todo['completed'] ?? false,
                        onChanged: (value) async {
                          await SyncLayer.collection('todos').save({
                            ...todo,
                            'completed': value,
                          }, id: todo['id']);
                        },
                      ),
                      title: Text(
                        todo['text'],
                        style: TextStyle(
                          decoration: todo['completed']
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await SyncLayer.collection('todos')
                              .delete(todo['id']);
                        },
                      ),
                    );
                  },
                );
              },
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
