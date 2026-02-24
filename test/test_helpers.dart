import 'dart:io';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Mock PathProviderPlatform for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    // Return a temporary directory for tests
    final tempDir = Directory.systemTemp.createTempSync('synclayer_test_');
    return tempDir.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    final tempDir = Directory.systemTemp.createTempSync('synclayer_test_temp_');
    return tempDir.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final tempDir =
        Directory.systemTemp.createTempSync('synclayer_test_support_');
    return tempDir.path;
  }
}

/// Mock ConnectivityPlatform for testing
class MockConnectivityPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements ConnectivityPlatform {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [ConnectivityResult.wifi];
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return Stream.value([ConnectivityResult.wifi]);
  }
}

/// Setup test environment with mocked path_provider, connectivity, and Isar
void setupTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = MockPathProviderPlatform();
  ConnectivityPlatform.instance = MockConnectivityPlatform();

  // Initialize Isar for tests (without download - should be pre-downloaded)
  try {
    Isar.initializeIsarCore(download: false);
  } catch (e) {
    // Already initialized, which is fine
  }
}
