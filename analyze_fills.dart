import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(r'C:\Users\ebrah\.gemini\antigravity-ide\brain\f70f1dd1-a23f-4c7d-a51a-4efcb74d6c44\.system_generated\steps\2778\output.txt');
  final data = jsonDecode(file.readAsStringSync());
  
  Map<String, dynamic>? targetNode;
  void findTarget(Map<String, dynamic> node) {
    if (node['id'] == '390:1911') {
      targetNode = node;
    }
    if (node.containsKey('children')) {
      for (final c in node['children']) {
        findTarget(c as Map<String, dynamic>);
      }
    }
  }

  final nodes = data['nodes'] as List<dynamic>? ?? [];
  for (final rootNode in nodes) {
    findTarget(rootNode as Map<String, dynamic>);
  }

  if (targetNode != null) {
    print('Fills: ${targetNode!['fills']}');
    print('Background: ${targetNode!['backgroundColor']}');
  }
}
