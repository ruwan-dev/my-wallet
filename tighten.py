import os

with open('lib/features/expenses/presentation/widgets/forecast_git_graph.dart', 'r') as f:
    content = f.read()

# Update totalWidth calculation and x coordinates
old_width_calc = '''    final double totalWidth = (colWidth / 2) + (nodes.length * colWidth) + (colWidth / 2);'''
new_width_calc = '''    final double startPadding = 15.0;
    final double totalWidth = startPadding + (nodes.length * colWidth) + (colWidth / 2);'''
content = content.replace(old_width_calc, new_width_calc)

old_coords = '''      final double prevX = i == 0 ? (colWidth / 2) : (colWidth / 2) + (i * colWidth);
      final double x = (colWidth / 2) + ((i + 1) * colWidth);'''
new_coords = '''      final double startPadding = 15.0;
      final double prevX = i == 0 ? startPadding : startPadding + (i * colWidth);
      final double x = startPadding + ((i + 1) * colWidth);'''
content = content.replace(old_coords, new_coords)

with open('lib/features/expenses/presentation/widgets/forecast_git_graph.dart', 'w') as f:
    f.write(content)

print("Done")
