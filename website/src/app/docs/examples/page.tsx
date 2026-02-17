import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft, Github } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Examples',
  description: 'Real-world code examples for SyncLayer SDK',
};

export default function ExamplesPage() {
  return (
    <div className="min-h-screen bg-white">
      <section className="px-6 py-12">
        <div className="max-w-4xl mx-auto">
          <Link
            href="/docs"
            className="inline-flex items-center text-gray-700 hover:text-black mb-8 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Documentation
          </Link>

          <h1 className="text-5xl font-bold text-black mb-4">Examples</h1>
          <p className="text-xl text-gray-700 mb-12">
            Real-world code examples and use cases for SyncLayer
          </p>

          <div className="prose prose-lg max-w-none">
            <Example
              title="Todo App with Offline Support"
              description="A complete todo application with offline-first architecture"
              code={`import 'package:flutter/material.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['todos'],
      conflictStrategy: ConflictStrategy.lastWriteWins,
    ),
  );
  
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
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
        title: Text('My Todos'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () => SyncLayer.syncNow(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SyncLayer.collection('todos').watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final todos = snapshot.data!;

          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                leading: Checkbox(
                  value: todo['done'] ?? false,
                  onChanged: (value) async {
                    await SyncLayer.collection('todos').save(
                      {'done': value},
                      id: todo['id'],
                    );
                  },
                ),
                title: Text(todo['text'] ?? ''),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await SyncLayer.collection('todos').delete(todo['id']);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Todo'),
        content: TextField(
          controller: _textController,
          decoration: InputDecoration(hintText: 'Enter todo text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_textController.text.isNotEmpty) {
                await SyncLayer.collection('todos').save({
                  'text': _textController.text,
                  'done': false,
                });
                _textController.clear();
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}`}
            />

            <Example
              title="Firebase Integration"
              description="Using SyncLayer with Firebase Firestore"
              code={`import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters/firebase_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize SyncLayer with Firebase adapter
  await SyncLayer.init(
    SyncConfig(
      collections: ['todos', 'users'],
      customBackendAdapter: FirebaseAdapter(
        firestore: FirebaseFirestore.instance,
      ),
      conflictStrategy: ConflictStrategy.lastWriteWins,
    ),
  );
  
  runApp(MyApp());
}`}
            />

            <Example
              title="Supabase Integration"
              description="Using SyncLayer with Supabase"
              code={`import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters/supabase_adapter.dart';

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
      collections: ['todos', 'users'],
      customBackendAdapter: SupabaseAdapter(
        client: Supabase.instance.client,
      ),
      conflictStrategy: ConflictStrategy.serverWins,
    ),
  );
  
  runApp(MyApp());
}`}
            />

            <Example
              title="Event Monitoring"
              description="Listen to sync events and handle errors"
              code={`import 'package:synclayer/synclayer.dart';

class SyncMonitor {
  StreamSubscription? _subscription;

  void startMonitoring() {
    _subscription = SyncLayer.events.listen((event) {
      if (event is SyncStartedEvent) {
        print('🔄 Sync started at \${event.timestamp}');
      } else if (event is SyncCompletedEvent) {
        print('✅ Sync completed: \${event.itemsSynced} items');
      } else if (event is SyncErrorEvent) {
        print('❌ Sync error: \${event.error}');
        // Handle error (show notification, retry, etc.)
      } else if (event is ConflictDetectedEvent) {
        print('⚠️ Conflict in \${event.collection}: \${event.entityId}');
      } else if (event is ConnectivityChangedEvent) {
        if (event.isOnline) {
          print('🌐 Back online - syncing...');
          SyncLayer.syncNow();
        } else {
          print('📴 Offline mode');
        }
      }
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
  }
}`}
            />

            <Example
              title="Custom Backend Adapter"
              description="Create a custom adapter for your own backend"
              code={`import 'package:synclayer/core/backend_adapter.dart';
import 'package:dio/dio.dart';

class CustomBackendAdapter implements BackendAdapter {
  final Dio _dio;
  final String _baseUrl;

  CustomBackendAdapter({
    required String baseUrl,
    String? authToken,
  })  : _baseUrl = baseUrl,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: authToken != null
              ? {'Authorization': 'Bearer \$authToken'}
              : null,
        ));

  @override
  Future<Map<String, dynamic>> pull(
    String collection,
    DateTime? lastSync,
  ) async {
    try {
      final response = await _dio.get(
        '/\$collection/sync',
        queryParameters: lastSync != null
            ? {'since': lastSync.toIso8601String()}
            : null,
      );
      return response.data;
    } catch (e) {
      throw Exception('Pull failed: \$e');
    }
  }

  @override
  Future<void> push(
    String collection,
    List<Map<String, dynamic>> changes,
  ) async {
    try {
      await _dio.post(
        '/\$collection/sync',
        data: {'changes': changes},
      );
    } catch (e) {
      throw Exception('Push failed: \$e');
    }
  }

  @override
  Future<void> delete(String collection, String id) async {
    try {
      await _dio.delete('/\$collection/\$id');
    } catch (e) {
      throw Exception('Delete failed: \$e');
    }
  }

  @override
  Future<void> updateAuthToken(String token) async {
    _dio.options.headers['Authorization'] = 'Bearer \$token';
  }
}

// Usage
await SyncLayer.init(
  SyncConfig(
    collections: ['todos'],
    customBackendAdapter: CustomBackendAdapter(
      baseUrl: 'https://api.example.com',
      authToken: 'your-token',
    ),
  ),
);`}
            />

            <Example
              title="Batch Operations"
              description="Efficiently handle multiple operations"
              code={`// Save multiple items
Future<void> saveBatch(List<Map<String, dynamic>> items) async {
  final collection = SyncLayer.collection('todos');
  
  for (final item in items) {
    await collection.save(item);
  }
  
  // Trigger sync once after all saves
  await SyncLayer.syncNow();
}

// Delete multiple items
Future<void> deleteBatch(List<String> ids) async {
  final collection = SyncLayer.collection('todos');
  
  for (final id in ids) {
    await collection.delete(id);
  }
  
  await SyncLayer.syncNow();
}

// Usage
await saveBatch([
  {'text': 'Task 1', 'done': false},
  {'text': 'Task 2', 'done': false},
  {'text': 'Task 3', 'done': false},
]);`}
            />

            <Example
              title="Query and Filter"
              description="Filter and query local data"
              code={`// Get all todos
final allTodos = await SyncLayer.collection('todos').getAll();

// Filter completed todos
final completedTodos = allTodos.where((todo) => todo['done'] == true).toList();

// Filter by text search
final searchResults = allTodos
    .where((todo) => 
        todo['text'].toString().toLowerCase().contains('buy'))
    .toList();

// Sort by date
final sortedTodos = allTodos
  ..sort((a, b) => 
      DateTime.parse(b['createdAt'])
          .compareTo(DateTime.parse(a['createdAt'])));

// Watch with filter
SyncLayer.collection('todos').watch().listen((todos) {
  final activeTodos = todos.where((t) => t['done'] == false).toList();
  print('Active todos: \${activeTodos.length}');
});`}
            />

            <div className="bg-green-50 border border-green-200 rounded-xl p-6 mt-12">
              <h3 className="text-lg font-bold text-black mb-2">Complete Example App</h3>
              <p className="text-gray-700 mb-4">
                Check out our complete example application on GitHub with more advanced features.
              </p>
              <a
                href="https://github.com/hostspicaindia/synclayer/tree/main/example"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-6 py-3 bg-black text-white rounded-lg hover:bg-gray-800 transition-colors font-semibold"
              >
                <Github className="w-5 h-5" />
                View on GitHub
              </a>
            </div>

            <div className="mt-12 pt-8 border-t border-gray-200">
              <h2 className="text-2xl font-bold text-black mb-4">More Resources</h2>
              <div className="grid md:grid-cols-2 gap-4">
                <ResourceCard
                  title="API Reference"
                  description="Complete API documentation"
                  href="/docs/api"
                />
                <ResourceCard
                  title="Architecture"
                  description="Technical architecture guide"
                  href="/docs/architecture"
                />
                <ResourceCard
                  title="Quick Start"
                  description="Get started in 5 minutes"
                  href="/docs/quick-start"
                />
                <ResourceCard
                  title="GitHub Repository"
                  description="Source code and issues"
                  href="https://github.com/hostspicaindia/synclayer"
                  external
                />
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}

function Example({ title, description, code }: { title: string; description: string; code: string }) {
  return (
    <div className="mb-12">
      <h2 className="text-2xl font-bold text-black mb-2">{title}</h2>
      <p className="text-gray-700 mb-4">{description}</p>
      <div className="bg-gray-900 rounded-xl overflow-hidden">
        <div className="flex items-center justify-between px-4 py-2 bg-gray-800 border-b border-gray-700">
          <span className="text-xs text-gray-300 font-mono">dart</span>
        </div>
        <pre className="p-4 overflow-x-auto">
          <code className="text-sm text-white font-mono whitespace-pre">{code}</code>
        </pre>
      </div>
    </div>
  );
}

function ResourceCard({
  title,
  description,
  href,
  external = false
}: {
  title: string;
  description: string;
  href: string;
  external?: boolean;
}) {
  const content = (
    <div className="block p-4 bg-gray-50 border border-gray-200 rounded-lg hover:border-black transition-colors">
      <h3 className="font-bold text-black mb-1">{title}</h3>
      <p className="text-sm text-gray-700">{description}</p>
    </div>
  );

  return external ? (
    <a href={href} target="_blank" rel="noopener noreferrer">
      {content}
    </a>
  ) : (
    <Link href={href}>{content}</Link>
  );
}
