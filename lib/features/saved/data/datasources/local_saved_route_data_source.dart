import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/saved_route_dto.dart';
import '../../domain/entities/saved_route.dart';

class LocalSavedRouteDataSource {
  static const String _fileName = 'wassla_saved_routes.json';
  String? _basePath;

  LocalSavedRouteDataSource({String? basePath}) {
    _basePath = basePath;
  }

  Future<String> get _filePath async {
    if (_basePath != null) return p.join(_basePath!, _fileName);
    final docs = await getApplicationDocumentsDirectory();
    _basePath = docs.path;
    return p.join(_basePath!, _fileName);
  }

  Future<List<SavedRoute>> readSavedRoutes() async {
    try {
      final file = File(await _filePath);
      if (!file.existsSync()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((e) => SavedRouteDto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> writeSavedRoutes(List<SavedRoute> entries) async {
    try {
      final file = File(await _filePath);
      final jsonList = entries.map((e) => SavedRouteDto.toJson(e)).toList();
      final contents = jsonEncode(jsonList);
      await file.writeAsString(contents);
    } catch (e) {
      // Best effort saving
    }
  }
}
