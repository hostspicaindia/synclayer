import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synclayer/synclayer.dart';
import 'firebase_options.dart';
import 'adapters/firebase_adapter.dart';
import 'screens/todo_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize SyncLayer with Firebase adapter
  // No backend server needed!
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://firebaseapp.com', // Not used with custom adapter
      customBackendAdapter: FirebaseAdapter(
        firestore: FirebaseFirestore.instance,
      ),
      syncInterval: const Duration(minutes: 5),
      collections: ['todos'],
      conflictStrategy: ConflictStrategy.lastWriteWins,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline-First Todo (SyncLayer + Firebase)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TodoScreen(),
    );
  }
}
