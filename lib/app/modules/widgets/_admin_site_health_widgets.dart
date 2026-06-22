part of 'admin_site_health_section.dart';

class _UptimeDot extends StatelessWidget {
  const _UptimeDot({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'up' => EColors.primary,
      'down' => const Color(0xFFFF4D4D),
      'degraded' => EColors.gold,
      _ => EColors.textSecondary,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LighthouseScores extends StatelessWidget {
  const _LighthouseScores({required this.quote});
  final Map<String, dynamic> quote;

  @override
  Widget build(BuildContext context) {
    final perf = quote['lighthouse_performance'] as int?;
    final acc = quote['lighthouse_accessibility'] as int?;
    final bp = quote['lighthouse_best_practices'] as int?;
    final seo = quote['lighthouse_seo'] as int?;

    if (perf == null && acc == null && bp == null && seo == null) {
      return const Text(
        'No audit data yet',
        style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
      );
    }

    final prevPerf = quote['lighthouse_performance_prev'] as int?;
    final prevAcc = quote['lighthouse_accessibility_prev'] as int?;
    final prevBp = quote['lighthouse_best_practices_prev'] as int?;
    final prevSeo = quote['lighthouse_seo_prev'] as int?;

    return Wrap(
      spacing: ESizes.sm,
      runSpacing: 4,
      children: [
        if (perf != null) _ScoreChip('Perf', perf, prevPerf),
        if (acc != null) _ScoreChip('A11y', acc, prevAcc),
        if (bp != null) _ScoreChip('BP', bp, prevBp),
        if (seo != null) _ScoreChip('SEO', seo, prevSeo),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip(this.label, this.score, this.prev);
  final String label;
  final int score;
  final int? prev;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? EColors.primary
        : score >= 50
        ? EColors.gold
        : const Color(0xFFFF4D4D);

    String delta = '';
    if (prev != null) {
      final diff = score - prev!;
      if (diff > 0) {
        delta = ' +$diff';
      } else if (diff < 0) {
        delta = ' $diff';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: ESizes.fontSizeLabel),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: EColors.textSecondary),
            ),
            TextSpan(
              text: '$score',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            if (delta.isNotEmpty)
              TextSpan(
                text: delta,
                style: TextStyle(
                  color: delta.startsWith(' +') ? EColors.primary : const Color(0xFFFF4D4D),
                  fontSize: ESizes.fontSizeLabel - 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});
  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final type = event['event_type'] as String? ?? '';
    final createdAt = event['created_at'] as String? ?? '';
    final (label, color) = switch (type) {
      'downtime_start' => ('⬇ Down', const Color(0xFFFF4D4D)),
      'downtime_end' => ('⬆ Up', EColors.primary),
      'audit_completed' => ('Audit', EColors.textSecondary),
      _ => (type, EColors.textSecondary),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: ESizes.fontSizeLabel),
          ),
          const SizedBox(width: 6),
          Text(
            _relativeTime(createdAt),
            style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
          ),
        ],
      ),
    );
  }

  String _relativeTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// Health badge dot for AdminQuoteRow — computed from quote fields
class HealthBadgeDot extends StatelessWidget {
  const HealthBadgeDot({super.key, required this.quote});
  final Map<String, dynamic> quote;

  @override
  Widget build(BuildContext context) {
    if ((quote['site_url'] as String?) == null) return const SizedBox.shrink();

    final status = quote['uptime_status'] as String? ?? 'unknown';
    final perf = quote['lighthouse_performance'] as int?;
    final acc = quote['lighthouse_accessibility'] as int?;
    final bp = quote['lighthouse_best_practices'] as int?;
    final seo = quote['lighthouse_seo'] as int?;

    final Color dotColor;
    if (status == 'unknown') {
      dotColor = EColors.textSecondary;
    } else if (status == 'down') {
      dotColor = const Color(0xFFFF4D4D);
    } else {
      final scores = [perf, acc, bp, seo].whereType<int>();
      final hasAny = scores.isNotEmpty;
      final anyBelow50 = hasAny && scores.any((s) => s < 50);
      final anyBelow80 = hasAny && scores.any((s) => s < 80);

      if (status == 'degraded' || anyBelow50) {
        dotColor = anyBelow50 ? const Color(0xFFFF4D4D) : EColors.gold;
      } else if (anyBelow80) {
        dotColor = EColors.gold;
      } else {
        dotColor = EColors.primary;
      }
    }

    return Tooltip(
      message: _tooltipMessage(status, quote),
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(right: ESizes.xs),
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
    );
  }

  String _tooltipMessage(String status, Map<String, dynamic> q) {
    final perf = q['lighthouse_performance'] as int?;
    final seo = q['lighthouse_seo'] as int?;
    if (status == 'unknown') return 'No health data yet';
    final parts = ['Uptime: $status'];
    if (perf != null) parts.add('Perf: $perf');
    if (seo != null) parts.add('SEO: $seo');
    return parts.join(' · ');
  }
}
