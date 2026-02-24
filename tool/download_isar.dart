import 'package:isar/isar.dart';

void main() async {
  print('Downloading Isar core library...');
  try {
    await Isar.initializeIsarCore(download: true);
    print('✓ Isar core library downloaded successfully');
  } catch (e) {
    print('✗ Failed to download Isar: $e');
  }
}
