import json
import collections

with open(r'C:\Users\ebrah\.gemini\antigravity-ide\brain\f70f1dd1-a23f-4c7d-a51a-4efcb74d6c44\.system_generated\steps\2427\output.txt', 'r', encoding='utf-8') as f:
    data = json.load(f)

node_types = collections.Counter()
colors = set()
font_styles = set()
screen_names = []
component_names = collections.Counter()

def traverse(node, depth=0):
    node_type = node.get('type')
    node_types[node_type] += 1
    
    name = node.get('name', '')
    
    if node_type == 'FRAME' and depth <= 3:
        # Likely a screen if it's high up
        if 'width' in node.get('cssStyles', {}) and node['cssStyles']['width'] in ['375px', '390px', '414px', '428px']:
            screen_names.append(name)
    
    if node_type in ['COMPONENT', 'INSTANCE'] or name.startswith('Btn') or 'Button' in name or 'Card' in name or 'Input' in name:
        component_names[name] += 1
        
    css = node.get('cssStyles', {})
    
    # Extract colors
    for key in ['backgroundColor', 'color', 'borderColor']:
        if key in css:
            c = css[key]
            if c != 'transparent' and c != 'rgba(0, 0, 0, 0)':
                colors.add(c)
                
    # Extract typography
    if 'fontFamily' in css and 'fontSize' in css:
        font_styles.add(f"{css.get('fontFamily')} {css.get('fontSize')} {css.get('fontWeight', 'normal')} {css.get('lineHeight', 'normal')}")
        
    for child in node.get('children', []):
        traverse(child, depth + 1)

for root_node in data.get('nodes', []):
    traverse(root_node)

print("--- NODE TYPES ---")
for k, v in node_types.most_common(): print(f"{k}: {v}")

print("\n--- COLORS ---")
for c in sorted(list(colors)): print(c)

print("\n--- TYPOGRAPHY ---")
for f in sorted(list(font_styles)): print(f)

print("\n--- SCREENS ---")
for s in screen_names: print(s)

print("\n--- COMMON COMPONENTS ---")
for k, v in component_names.most_common(20): print(f"{k}: {v}")
