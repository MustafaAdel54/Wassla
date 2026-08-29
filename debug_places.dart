import 'dart:convert';
import 'dart:io';

void main() {
  final places = <Map<String, dynamic>>[];
  
  // Load stations
  final stationsDir = Directory('assets/transport_data/stations');
  final stationIds = <String>{};
  if (stationsDir.existsSync()) {
    for (var f in stationsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      final content = f.readAsStringSync();
      final w = jsonDecode(content);
      final id = w['id'] as String;
      final o = w['data'] as Map<String, dynamic>;
      
      places.add({
        'id': id,
        'name': o['name'],
        'stationId': id,
        'type': 'station'
      });
      stationIds.add(id);
    }
  }

  // Load stops
  final stopsDir = Directory('assets/transport_data/stops');
  if (stopsDir.existsSync()) {
    for (var f in stopsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      final content = f.readAsStringSync();
      final w = jsonDecode(content);
      final id = w['id'] as String;
      final o = w['data'] as Map<String, dynamic>;
      final stationId = o['stationId'] as String?;

      if (stationId != null && stationIds.contains(stationId)) continue;
      
      if (stationId == null) {
        places.add({
          'id': id,
          'name': o['name'],
          'stationId': stationId,
          'type': 'stop'
        });
      }
    }
  }
  
  print('Total places parsed: \${places.length}');
  
  // Now find Helwan
  final helwans = places.where((p) => p['name'].toString().toLowerCase().contains('helwan')).toList();
  print('Helwans found: \${helwans.length}');
  for (var h in helwans) {
    print(h);
  }
}
