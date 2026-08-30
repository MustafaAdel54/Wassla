import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(r'C:\Users\ebrah\.gemini\antigravity-ide\brain\f70f1dd1-a23f-4c7d-a51a-4efcb74d6c44\.system_generated\steps\2427\output.txt');
  final data = jsonDecode(file.readAsStringSync());

  final components = <String, Map<String, dynamic>>{};

  void traverse(Map<String, dynamic> node) {
    final type = node['type'] as String? ?? '';
    final name = node['name'] as String? ?? '';
    final css = node['cssStyles'] as Map<String, dynamic>? ?? {};

    if (type == 'COMPONENT' || type == 'COMPONENT_SET') {
      if (name == 'Button' || name == 'Input' || name == 'Navbar' || name == 'Card' || name == 'Settings') {
        components[name] = {
          'type': type,
          'css': css,
          'children': (node['children'] as List<dynamic>? ?? []).map((c) {
             final cMap = c as Map<String, dynamic>;
             return {
               'name': cMap['name'],
               'type': cMap['type'],
               'css': cMap['cssStyles']
             };
          }).toList(),
        };
      }
    }
    
    // Also look for instances if we didn't find the main component
    if ((type == 'INSTANCE' || type == 'FRAME') && (name == 'Button' || name == 'Input' || name == 'Navbar' || name == 'Settings')) {
       if (!components.containsKey(name + '_instance')) {
          components[name + '_instance'] = {
            'type': type,
            'css': css,
            'children': (node['children'] as List<dynamic>? ?? []).map((c) {
               final cMap = c as Map<String, dynamic>;
               return {
                 'name': cMap['name'],
                 'type': cMap['type'],
                 'css': cMap['cssStyles']
               };
            }).toList(),
          };
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

  print(const JsonEncoder.withIndent('  ').convert(components));
}
