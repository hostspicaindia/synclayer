import 'package:flutter/material.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SyncLayer
  await SyncLayer.init(
    SyncConfig(
      baseUrl:
          'http://10.0.2.2:3000', // Android emulator uses 10.0.2.2 for localhost
      syncInterval: Duration(seconds: 10),
      enableAutoSync: true,
      collections: ['todos'], // Specify collections to sync
    ),
  );

  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SyncLayer Todo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final _textController = TextEditingController();
  bool _isOnline = true;
  int _syncEventCount = 0;

  @override
  void initState() {
    super.initState();
    _listenToSyncEvents();
  }

  void _listenToSyncEvents() {
    SyncLayerCore.instance.syncEngine.events.listen((event) {
      setState(() {
        _syncEventCount++;
      });

      // Show sync events in debug
      print('Sync Event: ${event.type}');
    });

    SyncLayerCore.instance.connectivityService.onConnectivityChanged.listen(
      (isOnline) {
        setState(() {
          _isOnline = isOnline;
        });
      },
    );
  }

  Future<void> _addTodo() async {
    if (_textController.text.isEmpty) return;

    await SyncLayer.collection('todos').save({
      'text': _textController.text,
      'completed': false,
      'createdAt': DateTime.now().toIso8601String(),
    });

    _textController.clear();
  }

  Future<void> _toggleTodo(String id, bool completed) async {
    await SyncLayer.collection('todos').save(
      {
        'completed': !completed,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      id: id,
    );
  }

  Future<void> _deleteTodo(String id) async {
    await SyncLayer.collection('todos').delete(id);
  }

  Future<void> _manualSync() async {
    await SyncLayer.syncNow();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sync triggered')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SyncLayer Todo'),
        actions: [
          // Connectivity indicator
          Padding(
            padding: EdgeInsets.all(16),
            child: Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _isOnline ? Colors.green : Colors.red,
            ),
          ),
          // Sync event counter
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Events: $_syncEventCount'),
            ),
          ),
          // Manual sync button
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: _manualSync,
          ),
        ],
      ),
      body: Column(
        children: [
          // Add todo input
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'What needs to be done?',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: Text('Add'),
                ),
              ],
            ),
          ),

          // Todo list
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
                    child: Text(
                      'No todos yet!\nAdd one above to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    final id = todo['id'] as String? ?? '';
                    final text = todo['text'] as String? ?? '';
                    final completed = todo['completed'] as bool? ?? false;

                    return ListTile(
                      leading: Checkbox(
                        value: completed,
                        onChanged: (_) => _toggleTodo(id, completed),
                      ),
                      title: Text(
                        text,
                        style: TextStyle(
                          decoration:
                              completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTodo(id),
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
