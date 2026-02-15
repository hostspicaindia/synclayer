/// Built-in backend adapters for popular platforms
///
/// SyncLayer provides ready-to-use adapters for:
/// - Firebase Firestore
/// - Supabase
/// - Appwrite
///
/// **IMPORTANT:** These adapters require their respective packages to be installed.
/// Only add the packages you need:
///
/// ```yaml
/// dependencies:
///   synclayer: ^0.1.0-alpha.6
///
///   # Add only what you need:
///   cloud_firestore: ^5.7.0      # For Firebase
///   supabase_flutter: ^2.9.0     # For Supabase
///   appwrite: ^14.0.0            # For Appwrite
/// ```
///
/// **Note:** The adapter files will show analyzer errors if their dependencies
/// are not installed. This is expected and normal - they are optional dependencies.
///
/// You can also create custom adapters by implementing [SyncBackendAdapter].
library adapters;

export 'firebase_adapter.dart';
export 'supabase_adapter.dart';
export 'appwrite_adapter.dart';
