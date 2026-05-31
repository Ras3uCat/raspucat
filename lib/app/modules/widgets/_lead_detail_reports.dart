part of 'admin_outreach_widget.dart';

class _LeadDetailReports extends StatefulWidget {
  const _LeadDetailReports({required this.lead});
  final LeadModel lead;

  @override
  State<_LeadDetailReports> createState() => _LeadDetailReportsState();
}

class _LeadDetailReportsState extends State<_LeadDetailReports> {
  int _activeTab = 0;

  List<_ReportTab> get _tabs => [
    if (widget.lead.blueprintMd != null)
      _ReportTab(label: 'Blueprint', content: widget.lead.blueprintMd!),
    if (widget.lead.brandBriefHtml != null)
      _ReportTab(label: 'Brand Brief', content: widget.lead.brandBriefHtml!),
    if (widget.lead.competitorHtml != null)
      _ReportTab(label: 'Competitor', content: widget.lead.competitorHtml!),
    if (widget.lead.brandAlignmentHtml != null)
      _ReportTab(label: 'Brand Alignment', content: widget.lead.brandAlignmentHtml!),
    if (widget.lead.customPlanMd != null)
      _ReportTab(label: 'Custom Plan', content: widget.lead.customPlanMd!),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportsSectionHeader(
          tabs: _tabs,
          activeTab: _activeTab,
          onTabChanged: (i) => setState(() => _activeTab = i),
        ),
        const SizedBox(height: ESizes.sm),
        if (!widget.lead.hasReports)
          _ReportsEmptyState()
        else
          _ReportBody(tabs: _tabs, activeTab: _activeTab),
      ],
    );
  }
}

class _ReportTab {
  const _ReportTab({required this.label, required this.content});
  final String label;
  final String content;
}

class _ReportsSectionHeader extends StatelessWidget {
  const _ReportsSectionHeader({
    required this.tabs,
    required this.activeTab,
    required this.onTabChanged,
  });
  final List<_ReportTab> tabs;
  final int activeTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '// REPORTS',
          style: TextStyle(
            color: EColors.primary.withAlpha(153),
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        if (tabs.isNotEmpty) ...[
          const SizedBox(width: ESizes.md),
          _SubTabPills(
            activeIndex: activeTab,
            labels: tabs.map((t) => t.label).toList(),
            onTap: onTabChanged,
          ),
        ],
      ],
    );
  }
}

class _ReportsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(6),
        border: Border.all(color: EColors.primary.withAlpha(30)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'No reports yet. Run /prepare-lead in Claude Code to generate the full intelligence package.',
        style: TextStyle(
          color: EColors.primary.withAlpha(102),
          fontSize: ESizes.fontSizeLabel,
          fontFamily: 'monospace',
          height: 1.6,
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.tabs, required this.activeTab});
  final List<_ReportTab> tabs;
  final int activeTab;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox.shrink();
    final safeIndex = activeTab.clamp(0, tabs.length - 1);
    final tab = tabs[safeIndex];
    return _ReportPane(label: tab.label, content: tab.content);
  }
}

class _ReportPane extends StatelessWidget {
  const _ReportPane({required this.label, required this.content});
  final String label;
  final String content;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          width: double.infinity,
          decoration: BoxDecoration(
            color: EColors.primary.withAlpha(6),
            border: Border.all(color: EColors.primary.withAlpha(30)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(ESizes.md, ESizes.md, ESizes.xl + ESizes.sm, ESizes.md),
            child: SelectableText(
              content,
              style: TextStyle(
                fontFamily: 'monospace',
                color: EColors.primary.withAlpha(204),
                fontSize: ESizes.fontSizeLabel,
                height: 1.6,
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: _ReportCopyButton(onTap: () => _copyToClipboard(context)),
        ),
      ],
    );
  }
}

class _ReportCopyButton extends StatelessWidget {
  const _ReportCopyButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Copy to clipboard',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: EColors.primary.withAlpha(20),
            border: Border.all(color: EColors.primary.withAlpha(51)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Icon(Icons.copy, color: EColors.primary, size: 12),
        ),
      ),
    );
  }
}
