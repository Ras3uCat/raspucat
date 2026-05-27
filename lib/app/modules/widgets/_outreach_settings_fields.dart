part of 'admin_outreach_widget.dart';

class _DiscoverySection extends StatelessWidget {
  const _DiscoverySection({required this.ctrl, required this.discoveryRunsCtrl});
  final AdminOutreachController ctrl;
  final TextEditingController discoveryRunsCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '// DISCOVERY',
          style: TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        Row(
          children: [
            SizedBox(
              width: 140,
              child: _SettingsNumberField(
                label: 'Discovery runs/week',
                ctrl: discoveryRunsCtrl,
                min: 1,
                max: 7,
              ),
            ),
            const SizedBox(width: ESizes.lg),
            Obx(() {
              final s = ctrl.settings.value;
              if (s.nextDiscoveryRunAt == null) return const SizedBox.shrink();
              final diff = s.nextDiscoveryRunAt!.difference(DateTime.now());
              final label = diff.isNegative
                  ? 'Overdue'
                  : diff.inDays > 0
                  ? 'Next run in ${diff.inDays}d'
                  : 'Next run in ${diff.inHours}h';
              return Text(
                label,
                style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
              );
            }),
          ],
        ),
        const SizedBox(height: ESizes.md),
        const Text(
          'INDUSTRY PROFILES',
          style: TextStyle(
            color: EColors.softGrey,
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Obx(() {
          final profiles = ctrl.industryProfiles;
          if (profiles.isEmpty) {
            return Text(
              'No profiles synced. Run /industry-download then sync here.',
              style: TextStyle(
                color: EColors.softGrey.withAlpha(153),
                fontSize: ESizes.fontSizeLabel,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: profiles.map((p) {
              final diff = DateTime.now().difference(p.researchedAt);
              final age = diff.inDays > 30
                  ? '${(diff.inDays / 30).round()}mo ago'
                  : '${diff.inDays}d ago';
              final bm = p.benchmark;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 12, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          p.name,
                          style: const TextStyle(
                            color: EColors.cyanTintedWhite,
                            fontSize: ESizes.fontSizeLabel,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· researched $age · ${p.painPoints.length} pain points',
                          style: const TextStyle(
                            color: EColors.softGrey,
                            fontSize: ESizes.fontSizeLabel,
                          ),
                        ),
                      ],
                    ),
                    if (bm != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: Wrap(
                          spacing: ESizes.sm,
                          runSpacing: 4,
                          children: [
                            _BenchmarkChip(
                              label: bm.avgPagespeed != null
                                  ? 'Avg speed: ${bm.avgPagespeed}'
                                  : 'No speed data',
                              color: bm.avgPagespeed == null
                                  ? EColors.softGrey
                                  : bm.avgPagespeed! < 50
                                  ? Colors.redAccent
                                  : bm.avgPagespeed! < 70
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            _BenchmarkChip(
                              label: '${(bm.pctDiyPlatform * 100).round()}% on DIY',
                              color: bm.pctDiyPlatform > 0.5 ? Colors.orange : EColors.softGrey,
                            ),
                            _BenchmarkChip(
                              label: '${(bm.pctWithBookingCta * 100).round()}% have booking CTA',
                              color: bm.pctWithBookingCta < 0.4 ? Colors.orange : EColors.softGrey,
                            ),
                            _BenchmarkChip(
                              label: 'n=${bm.sampleSize} · ${bm.sampledAt}',
                              color: EColors.softGrey,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: Text(
                          'No benchmark yet — run benchmark-industry after syncing',
                          style: TextStyle(
                            color: EColors.softGrey.withAlpha(128),
                            fontSize: ESizes.fontSizeLabel,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

class _SettingsNumberField extends StatelessWidget {
  const _SettingsNumberField({
    required this.label,
    required this.ctrl,
    required this.min,
    required this.max,
  });
  final String label;
  final TextEditingController ctrl;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: EColors.softGrey,
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeSm),
          decoration: InputDecoration(
            hintText: '$min–$max',
            hintStyle: TextStyle(color: EColors.softGrey.withAlpha(128)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: EColors.primary.withAlpha(77)),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: EColors.primary),
              borderRadius: BorderRadius.circular(4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: ESizes.sm),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _BenchmarkChip extends StatelessWidget {
  const _BenchmarkChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        border: Border.all(color: color.withAlpha(77)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: ESizes.fontSizeLabel),
      ),
    );
  }
}
