import 'package:flutter/material.dart';
import 'package:argus/features/detail/show_view_model.dart';

class SourceFilterBar extends StatelessWidget {
  final ShowViewModel viewModel;
  final int? selectedSourceId;
  final int totalItems;
  final ValueChanged<int?> onSourceSelected;

  const SourceFilterBar({
    super.key,
    required this.viewModel,
    required this.selectedSourceId,
    required this.totalItems,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) return const SizedBox.shrink();

    final filteredCount = viewModel.filteredItems.length;
    final contributingSources = viewModel.contributingSources;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedSourceId == null
                ? '$totalItems items'
                : '$filteredCount of $totalItems items',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (contributingSources.length > 1) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    showCheckmark: false,
                    selected: selectedSourceId == null,
                    label: const Text('All Sources'),
                    onSelected: (selected) {
                      if (selected) {
                        onSourceSelected(null);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ...contributingSources.map((source) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        showCheckmark: false,
                        selected: selectedSourceId == source.id,
                        label: Text(source.name),
                        onSelected: (selected) {
                          onSourceSelected(selected ? source.id : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
