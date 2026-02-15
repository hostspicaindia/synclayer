/// Example: Using SyncLayer with Firebase Firestore
///
/// This example shows how to integrate SyncLayer with Firebase Firestore
/// for automatic offline-first sync.
///
/// Setup:
/// 1. Add dependencies to pubspec.yaml:
///    - firebase_core: ^3.10.0
///    - cloud_firestore: ^5.7.0
///    - synclayer: ^0.1.0
///
/// 2. Configure Firebase in your app (follow Firebase setup guide)
///
/// 3. Run this example

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize SyncLayer with Firebase adapter
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://firebaseapp.com', // Not used with Firebase
      customBackendAdapter: FirebaseAdapter(
        firestore: FirebaseFirestore.instance,
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
      title: 'SyncLayer + Firebase',
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
        title: Text('Todos (Firebase)'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () async {
              await SyncLayer.syncNow();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Synced with Firebase')),
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
                          // Update todo
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
