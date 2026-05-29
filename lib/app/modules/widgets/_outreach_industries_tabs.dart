part of 'admin_outreach_widget.dart';

class _BenchmarksTab extends StatelessWidget {
  const _BenchmarksTab({required this.benchmark});
  final IndustryBenchmark? benchmark;

  @override
  Widget build(BuildContext context) {
    if (benchmark == null) {
      return Text(
        'No benchmark data yet. Run the benchmark step in /industry-setup to sample 15 live sites.',
        style: TextStyle(color: EColors.primary.withAlpha(102), fontSize: ESizes.fontSizeLabel),
      );
    }
    final b = benchmark!;
    final rows = [
      ('Sample size', '${b.sampleSize} sites'),
      ('Sampled', b.sampledAt),
      ('Avg PageSpeed', b.avgPagespeed != null ? '${b.avgPagespeed}/100' : 'N/A'),
      ('Have booking CTA', '${(b.pctWithBookingCta * 100).round()}%'),
      ('On DIY platform', '${(b.pctDiyPlatform * 100).round()}%'),
      ('Using HTTPS', '${(b.pctHttps * 100).round()}%'),
      ('Mobile viewport', '${(b.pctMobileViewport * 100).round()}%'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(6),
        border: Border.all(color: EColors.primary.withAlpha(30)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: ESizes.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    row.$1,
                    style: TextStyle(
                      color: EColors.primary.withAlpha(153),
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
                ),
                Text(
                  row.$2,
                  style: const TextStyle(
                    color: EColors.primary,
                    fontSize: ESizes.fontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MarkdownTab extends StatelessWidget {
  const _MarkdownTab({required this.content});
  final String? content;

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return Text(
        'Not yet synced. Run /industry-setup to generate.',
        style: TextStyle(color: EColors.primary.withAlpha(102), fontSize: ESizes.fontSizeLabel),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(6),
        border: Border.all(color: EColors.primary.withAlpha(30)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        content!,
        style: TextStyle(
          color: EColors.primary.withAlpha(204),
          fontSize: ESizes.fontSizeLabel,
          fontFamily: 'monospace',
          height: 1.6,
        ),
      ),
    );
  }
}
