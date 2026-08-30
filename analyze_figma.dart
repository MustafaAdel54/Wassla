import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(r'C:\Users\ebrah\.gemini\antigravity-ide\brain\f70f1dd1-a23f-4c7d-a51a-4efcb74d6c44\.system_generated\steps\2427\output.txt');
  final data = jsonDecode(file.readAsStringSync());

  final nodeTypes = <String, int>{};
  final colors = <String>{};
  final fontStyles = <String>{};
  final screenNames = <String>[];
  final componentNames = <String, int>{};

  void traverse(Map<String, dynamic> node, int depth) {
    final type = node['type'] as String? ?? '';
    nodeTypes[type] = (nodeTypes[type] ?? 0) + 1;
    
    final name = node['name'] as String? ?? '';
    final css = node['cssStyles'] as Map<String, dynamic>? ?? {};

    if (type == 'FRAME' && depth <= 3) {
      final width = css['width'] as String?;
      if (width == '375px' || width == '390px' || width == '414px' || width == '428px') {
        screenNames.add(name);
      }
    }

    if (type == 'COMPONENT' || type == 'INSTANCE' || name.startsWith('Btn') || name.contains('Button') || name.contains('Card') || name.contains('Input')) {
      componentNames[name] = (componentNames[name] ?? 0) + 1;
    }

    for (final key in ['backgroundColor', 'color', 'borderColor']) {
      if (css.containsKey(key)) {
        final c = css[key] as String;
        if (c != 'transparent' && !c.startsWith('rgba(0, 0, 0, 0')) {
          colors.add(c);
        }
      }
    }

    if (css.containsKey('fontFamily') && css.containsKey('fontSize')) {
      fontStyles.add("${css['fontFamily']} ${css['fontSize']} ${css['fontWeight'] ?? 'normal'} ${css['lineHeight'] ?? 'normal'}");
    }

    if (node.containsKey('children')) {
      for (final child in node['children']) {
        traverse(child as Map<String, dynamic>, depth + 1);
      }
    }
  }

  final nodes = data['nodes'] as List<dynamic>? ?? [];
  for (final rootNode in nodes) {
    traverse(rootNode as Map<String, dynamic>, 0);
  }

  print("--- NODE TYPES ---");
  for (final entry in nodeTypes.entries) {
    print("${entry.key}: ${entry.value}");
  }

  print("\n--- COLORS ---");
  final sortedColors = colors.toList()..sort();
  for (final c in sortedColors) {
    print(c);
  }

  print("\n--- TYPOGRAPHY ---");
  final sortedFonts = fontStyles.toList()..sort();
  for (final f in sortedFonts) {
    print(f);
  }

  print("\n--- SCREENS ---");
  for (final s in screenNames) {
    print(s);
  }

  print("\n--- COMMON COMPONENTS ---");
  final sortedComponents = componentNames.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  for (int i = 0; i < (sortedComponents.length > 20 ? 20 : sortedComponents.length); i++) {
    print("${sortedComponents[i].key}: ${sortedComponents[i].value}");
  }
}
