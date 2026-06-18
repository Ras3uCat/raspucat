part of 'admin_outreach_widget.dart';

Color _scoreColor(int score) {
  if (score >= 70) return Colors.green;
  if (score >= 40) return Colors.orange;
  return Colors.redAccent;
}

Color _statusColor(String status) {
  switch (status) {
    case 'prospect':
      return Colors.grey;
    case 'contacted':
      return Colors.blue;
    case 'replied':
      return EColors.primary;
    case 'call_booked':
      return Colors.purple;
    case 'proposal_sent':
      return Colors.orange;
    case 'closed_won':
      return Colors.green;
    case 'closed_lost':
    case 'unsubscribed':
      return Colors.red.shade900;
    default:
      return Colors.grey;
  }
}

String _relativeTime(DateTime? dt) {
  if (dt == null) return '—';
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  return '${diff.inMinutes}m ago';
}

class _OutreachPipelineView extends StatefulWidget {
  const _OutreachPipelineView({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  State<_OutreachPipelineView> createState() => _OutreachPipelineViewState();
}

class _OutreachPipelineViewState extends State<_OutreachPipelineView> {
  final _search = TextEditingController();
  // Local RxString keeps the Obx subscribed to search changes without touching the controller
  final _query = ''.obs;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => _query.value = _search.text.toLowerCase());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final query = _query.value;
      if (widget.ctrl.pipelineViewMode.value == 1) {
        return _OutreachKanbanView(ctrl: widget.ctrl, searchQuery: query);
      }
      final leads = widget.ctrl.filteredLeadsByStatus
          .where((l) => query.isEmpty || l.companyName.toLowerCase().contains(query))
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IndustryFilterBar(ctrl: widget.ctrl),
          _PipelineSearchField(
            search: _search,
            query: query,
            onClear: () {
              _search.clear();
              _query.value = '';
            },
          ),
          if (leads.isEmpty && query.isNotEmpty)
            Expanded(
              child: Center(
                child: Text(
                  "No companies match '$query'",
                  style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeSm),
                ),
              ),
            )
          else if (leads.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No leads yet.',
                  style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeSm),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ESizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PipelineTableHeader(),
                    const SizedBox(height: ESizes.sm),
                    ...leads.asMap().entries.map(
                      (e) => _LeadRow(lead: e.value, ctrl: widget.ctrl, index: e.key + 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _PipelineSearchField extends StatelessWidget {
  const _PipelineSearchField({required this.search, required this.query, required this.onClear});
  final TextEditingController search;
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.sm, ESizes.lg, 0),
      child: SizedBox(
        width: ESizes.searchFieldWidth,
        child: TextField(
          controller: search,
          style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeLabel),
          decoration: InputDecoration(
            hintText: 'Search companies...',
            hintStyle: TextStyle(
              color: EColors.softGrey.withAlpha(153),
              fontSize: ESizes.fontSizeLabel,
            ),
            suffixIcon: query.isNotEmpty
                ? GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close, color: EColors.softGrey, size: 14),
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
              borderSide: BorderSide(color: EColors.primary.withAlpha(50)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
              borderSide: const BorderSide(color: EColors.primary),
            ),
            filled: true,
            fillColor: EColors.primary.withAlpha(8),
          ),
        ),
      ),
    );
  }
}

class _PipelineTableHeader extends StatelessWidget {
  const _PipelineTableHeader();

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: EColors.softGrey,
      fontSize: ESizes.fontSizeLabel,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
      child: Row(
        children: const [
          SizedBox(width: 32, child: Text('#', style: labelStyle)),
          Expanded(flex: 3, child: Text('COMPANY', style: labelStyle)),
          Expanded(flex: 2, child: Text('INDUSTRY', style: labelStyle)),
          Expanded(flex: 2, child: Text('LOCATION', style: labelStyle)),
          SizedBox(width: 56, child: Text('SCORE', style: labelStyle)),
          Expanded(flex: 2, child: Text('STATUS', style: labelStyle)),
          Expanded(flex: 2, child: Text('LAST CONTACT', style: labelStyle)),
          SizedBox(width: 80, child: Text('ACTIONS', style: labelStyle)),
        ],
      ),
    );
  }
}
