import 'package:flutter/material.dart';

enum TimelineNodeState { completed, current, upcoming }

class TimelineEvent {
  final String title;
  final String subtitle;
  final TimelineNodeState state;

  const TimelineEvent({
    required this.title,
    required this.subtitle,
    required this.state,
  });
}

class RecurringTimelineWidget extends StatelessWidget {
  final List<TimelineEvent> events;

  const RecurringTimelineWidget({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Timeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          ...List.generate(events.length, (index) {
            return _TimelineRow(
              event: events[index],
              isLast: index == events.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _TimelineRow({
    required this.event,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color nodeColor;
    Color lineColor;
    IconData? nodeIcon;
    double nodeSize = 16.0;

    switch (event.state) {
      case TimelineNodeState.completed:
        nodeColor = Colors.green.shade400;
        lineColor = Colors.green.shade400;
        nodeIcon = Icons.check_circle_rounded;
        nodeSize = 20.0;
        break;
      case TimelineNodeState.current:
        nodeColor = colorScheme.primary;
        lineColor = colorScheme.onSurface.withOpacity(0.15); // Future line
        nodeSize = 20.0;
        nodeIcon = Icons.circle;
        break;
      case TimelineNodeState.upcoming:
        nodeColor = colorScheme.onSurface.withOpacity(0.3);
        lineColor = colorScheme.onSurface.withOpacity(0.15);
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline graphics column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    color: event.state == TimelineNodeState.upcoming
                        ? Colors.transparent
                        : nodeColor,
                    shape: BoxShape.circle,
                    border: event.state == TimelineNodeState.upcoming
                        ? Border.all(color: nodeColor, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: nodeIcon != null && event.state == TimelineNodeState.completed
                      ? Icon(nodeIcon, size: 20, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: event.state == TimelineNodeState.current
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: event.state == TimelineNodeState.upcoming
                          ? colorScheme.onSurface.withOpacity(0.5)
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
