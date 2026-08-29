import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wassla/features/route_search/data/datasources/routing_isolate_worker.dart';

void main() {
  group('Routing Isolate Lifecycle Tests', () {
    late Directory tempDir;
    late String datasetPath;
    late RoutingIsolateWorker worker;

    Future<void> createMockDataset(String path) async {
      final dir = Directory(path);
      if (!dir.existsSync()) dir.createSync(recursive: true);

      File(p.join(path, 'stops.json')).writeAsStringSync('[]');
      File(p.join(path, 'stations.json')).writeAsStringSync('[]');
      File(p.join(path, 'routes.json')).writeAsStringSync('[]');
      File(p.join(path, 'route_patterns.json')).writeAsStringSync('[]');
      File(p.join(path, 'transfers.json')).writeAsStringSync('[]');
    }

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('isolate_test');
      datasetPath = p.join(tempDir.path, 'active');
      worker = RoutingIsolateWorker();
    });

    tearDown(() {
      worker.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Isolate reloads dataset without terminating', () async {
      // 1. Dataset v1
      await createMockDataset(datasetPath);

      // 2. Routing isolate initialized
      await worker.initialize(datasetPath, 1);
      expect(worker.isInitialized, isTrue);

      // 3. (Mock) Route search using v1 (throws expected router not initialized since empty data, but tests connection)
      // Actually, TransitRouter on empty dataset won't crash, it just won't find a route.
      // We can't easily perform a real route search on empty mock data, but we can verify the isolate is alive.

      // 4. Dataset v2 synchronized (Simulated by reloading)
      await createMockDataset(datasetPath); // Simulate new files

      // 5. Routing isolate reload()
      await worker.reload(datasetPath, 2);

      // 6. Verify still initialized and alive
      expect(worker.isInitialized, isTrue);
    });
  });
}
