import os

with open('lib/features/expenses/presentation/widgets/forecast_git_graph.dart', 'r') as f:
    content = f.read()

content = content.replace('final double fixedLeftWidth = 90.0;', 'final double fixedLeftWidth = 85.0;')

# Replace size.width - 8 with 0 for text drawing in FixedLabelsPainter
content = content.replace('size.width - 8', '0')

# Replace TextAlign.right with TextAlign.left
content = content.replace('TextAlign.right', 'TextAlign.left')

with open('lib/features/expenses/presentation/widgets/forecast_git_graph.dart', 'w') as f:
    f.write(content)

print("Done")
