import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/history_entry_dto.dart';
import '../../domain/entities/history_entry.dart';

class LocalHistoryDataSource {
  static const String _fileName = 'wassla_history.json';
  String? _basePath;

  LocalHistoryDataSource({String? basePath}) : _basePath = basePath;

  Future<String> get _filePath async {
    if (_basePath != null) return p.join(_basePath!, _fileName);
    final docs = await getApplicationDocumentsDirectory();
    _basePath = docs.path;
    return p.join(_basePath!, _fileName);
  }

  Future<List<HistoryEntry>> readHistory() async {
    try {
      final file = File(await _filePath);
      if (!file.existsSync()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((e) => HistoryEntryDto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      // In case of parsing error or other issue, return empty
      return [];
    }
  }

  Future<void> writeHistory(List<HistoryEntry> entries) async {
    try {
      final file = File(await _filePath);
      final jsonList = entries.map((e) => HistoryEntryDto.toJson(e)).toList();
      final contents = jsonEncode(jsonList);
      await file.writeAsString(contents);
    } catch (e) {
      // Best effort saving
    }
  }
}
