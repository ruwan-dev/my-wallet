import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

class CategoryPickerSheet extends StatelessWidget {
  final Category selectedCategory;

  const CategoryPickerSheet({super.key, required this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = DefaultCategories.all;

    return Container(
      padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 40),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select Category',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.id == selectedCategory.id;

                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(category),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withOpacity(0.15)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(color: theme.colorScheme.primary, width: 2)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(category.icon, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
