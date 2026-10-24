import 'package:flutter/material.dart';

import '../../../../core/time_format.dart';
import '../../../../domain/analytics/activity_summary.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/riming_surface_card.dart';

/// Compact total + Top3 card for history (phone = light summary only).
class HistorySummaryCard extends StatelessWidget {
  const HistorySummaryCard({
    super.key,
    required this.label,
    required this.summary,
    this.hint,
  });

  final String label;
  final ActivitySummary summary;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RimingSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatDuration(summary.total),
                style: textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (summary.top.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '暂无事项',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < summary.top.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Text(
                    '${i + 1}.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      summary.top[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    formatDuration(summary.top[i].duration),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              hint!,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
