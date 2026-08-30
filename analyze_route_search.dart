import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(r'C:\Users\ebrah\.gemini\antigravity-ide\brain\f70f1dd1-a23f-4c7d-a51a-4efcb74d6c44\.system_generated\steps\2778\output.txt');
  final data = jsonDecode(file.readAsStringSync());

  void printStructure(Map<String, dynamic> node, int depth) {
    final name = node['name'] ?? 'Unnamed';
    final type = node['type'] ?? 'Unknown';
    final id = node['id'] ?? 'NoID';
    
    // Extract design info
    String extra = '';
    
    // Layout and spacing
    if (node['layoutMode'] != null) {
      extra += ' Layout: ${node['layoutMode']}';
    }
    if (node['itemSpacing'] != null) {
      extra += ' Spacing: ${node['itemSpacing']}';
    }
    if (node['paddingLeft'] != null) {
      extra += ' Pad: ${node['paddingLeft']},${node['paddingTop']},${node['paddingRight']},${node['paddingBottom']}';
    }
    
    // Constraints & resizing
    if (node['constraints'] != null) {
      extra += ' Constraints: ${node['constraints']}';
    }
    if (node['primaryAxisSizingMode'] != null) {
      extra += ' P-Axis: ${node['primaryAxisSizingMode']}';
    }
    if (node['counterAxisSizingMode'] != null) {
      extra += ' C-Axis: ${node['counterAxisSizingMode']}';
    }
    
    // Styles
    if (node['cornerRadius'] != null) {
      extra += ' Radius: ${node['cornerRadius']}';
    }
    
    print('${'  ' * depth}- $name ($type) [$id] $extra');
    
    if (node.containsKey('children')) {
      for (final c in node['children']) {
        printStructure(c as Map<String, dynamic>, depth + 1);
      }
    }
  }

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
    print('=== Target Node 390:1911 ===');
    printStructure(targetNode!, 0);
  } else {
    print('Node 390:1911 not found in the output!');
  }
}
