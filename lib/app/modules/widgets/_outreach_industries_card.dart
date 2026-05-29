part of 'admin_outreach_widget.dart';

class _IndustryCard extends StatefulWidget {
  const _IndustryCard({required this.profile});
  final IndustryProfileModel profile;

  @override
  State<_IndustryCard> createState() => _IndustryCardState();
}

class _IndustryCardState extends State<_IndustryCard> {
  bool _expanded = false;
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(10),
        border: Border.all(color: EColors.primary.withAlpha(51)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IndustryCardHeader(
            profile: widget.profile,
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            _IndustryCardBody(
              profile: widget.profile,
              activeTab: _activeTab,
              onTabChanged: (i) => setState(() => _activeTab = i),
            ),
        ],
      ),
    );
  }
}

class _IndustryCardHeader extends StatelessWidget {
  const _IndustryCardHeader({required this.profile, required this.expanded, required this.onTap});

  final IndustryProfileModel profile;
  final bool expanded;
  final VoidCallback onTap;

  String _formatDate(DateTime dt) =>
      '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(ESizes.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      color: EColors.primary,
                      fontSize: ESizes.fontSizeSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.slug,
                    style: TextStyle(
                      color: EColors.primary.withAlpha(102),
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
                  const SizedBox(height: ESizes.xs),
                  Text(
                    'Researched ${_formatDate(profile.researchedAt)}',
                    style: TextStyle(
                      color: EColors.primary.withAlpha(102),
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
                  if (profile.benchmark != null) ...[
                    const SizedBox(height: ESizes.sm),
                    _BenchmarkBadgeRow(benchmark: profile.benchmark!),
                  ],
                ],
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.chevron_right,
              color: EColors.primary.withAlpha(153),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _BenchmarkBadgeRow extends StatelessWidget {
  const _BenchmarkBadgeRow({required this.benchmark});
  final IndustryBenchmark benchmark;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ESizes.xs,
      runSpacing: ESizes.xs,
      children: [
        if (benchmark.avgPagespeed != null)
          _BenchmarkChip(label: 'PageSpeed ${benchmark.avgPagespeed}', color: EColors.primary),
        _BenchmarkChip(
          label: '${(benchmark.pctWithBookingCta * 100).round()}% booking CTA',
          color: EColors.primary,
        ),
        _BenchmarkChip(
          label: '${(benchmark.pctDiyPlatform * 100).round()}% DIY platform',
          color: EColors.primary,
        ),
      ],
    );
  }
}

class _IndustryCardBody extends StatelessWidget {
  const _IndustryCardBody({
    required this.profile,
    required this.activeTab,
    required this.onTabChanged,
  });

  final IndustryProfileModel profile;
  final int activeTab;
  final ValueChanged<int> onTabChanged;

  static const _tabLabels = ['Overview', 'Ride-Along', 'Money Map', 'Client Locator'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: EColors.primary.withAlpha(30)),
        Padding(
          padding: const EdgeInsets.fromLTRB(ESizes.md, ESizes.md, ESizes.md, 0),
          child: _SubTabPills(activeIndex: activeTab, labels: _tabLabels, onTap: onTabChanged),
        ),
        Padding(
          padding: const EdgeInsets.all(ESizes.md),
          child: _IndustryTabContent(profile: profile, activeTab: activeTab),
        ),
      ],
    );
  }
}

class _IndustryTabContent extends StatelessWidget {
  const _IndustryTabContent({required this.profile, required this.activeTab});
  final IndustryProfileModel profile;
  final int activeTab;

  @override
  Widget build(BuildContext context) {
    switch (activeTab) {
      case 0:
        return _MarkdownTab(content: profile.overviewMd);
      case 1:
        return _MarkdownTab(content: profile.rideAlongMd);
      case 2:
        return _MarkdownTab(content: profile.moneyMapMd);
      case 3:
        return _MarkdownTab(content: profile.clientLocatorMd);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _PainPointsTab extends StatelessWidget {
  const _PainPointsTab({required this.painPoints});
  final List<String> painPoints;

  @override
  Widget build(BuildContext context) {
    if (painPoints.isEmpty) {
      return Text(
        'No pain points recorded.',
        style: TextStyle(color: EColors.primary.withAlpha(102), fontSize: ESizes.fontSizeLabel),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: painPoints
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: ESizes.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '- ',
                    style: TextStyle(
                      color: EColors.primary.withAlpha(153),
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(
                        color: EColors.primary,
                        fontSize: ESizes.fontSizeLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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
