import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(r'C:\Users\ebrah\.gemini\antigravity-ide\brain\f70f1dd1-a23f-4c7d-a51a-4efcb74d6c44\.system_generated\steps\2427\output.txt');
  final data = jsonDecode(file.readAsStringSync());

  final screens = <String, Map<String, dynamic>>{};

  void traverse(Map<String, dynamic> node) {
    final type = node['type'] as String? ?? '';
    final name = node['name'] as String? ?? '';
    
    if (type == 'FRAME' && (name == 'GuideMe' || name == 'GuideMe Empty State')) {
      if (!screens.containsKey(name)) {
        screens[name] = node;
      }
    }

    if (node.containsKey('children')) {
      for (final child in node['children']) {
        traverse(child as Map<String, dynamic>);
      }
    }
  }

  final nodes = data['nodes'] as List<dynamic>? ?? [];
  for (final rootNode in nodes) {
    traverse(rootNode as Map<String, dynamic>);
  }

  // Print summary of structure
  void printStructure(Map<String, dynamic> node, int depth) {
      final name = node['name'];
      final type = node['type'];
      print('${'  ' * depth}- $name ($type)');
      if (node.containsKey('children')) {
          for (final c in node['children']) {
              printStructure(c as Map<String, dynamic>, depth + 1);
          }
      }
  }

  for (final entry in screens.entries) {
      print('=== ${entry.key} ===');
      printStructure(entry.value, 0);
  }
}
