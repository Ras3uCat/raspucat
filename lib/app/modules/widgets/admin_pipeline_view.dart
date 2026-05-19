import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/modules/widgets/admin_quote_detail_drawer.dart';

// ─── Pipeline column config ────────────────────────────────────────────────

class _PipelineColumn {
  const _PipelineColumn({required this.status, required this.label});
  final String status;
  final String label;
}

const _columns = [
  _PipelineColumn(status: 'pending', label: 'Pending'),
  _PipelineColumn(status: 'deposit_paid', label: 'Deposit Paid'),
  _PipelineColumn(status: 'fully_paid', label: 'Fully Paid'),
  _PipelineColumn(status: 'active', label: 'Active'),
];

// ─── Status color helper ───────────────────────────────────────────────────

Color _statusColor(String status) => switch (status) {
  'active' => EColors.primary,
  'fully_paid' => EColors.primary,
  'deposit_paid' => EColors.gold,
  _ => EColors.textSecondary,
};

// ─── Pipeline view ─────────────────────────────────────────────────────────

class AdminPipelineView extends StatelessWidget {
  const AdminPipelineView({super.key, required this.ctrl});
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 700) {
      return _WideLayout(ctrl: ctrl);
    }
    return _NarrowLayout(ctrl: ctrl);
  }
}

// ─── Wide (3-column row) ───────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.ctrl});
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _columns
          .map(
            (col) => Expanded(
              child: _PipelineColumnWidget(ctrl: ctrl, column: col),
            ),
          )
          .toList(),
    );
  }
}

// ─── Narrow (tabbed) ──────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.ctrl});
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _columns.length,
      child: Column(
        children: [
          TabBar(
            indicatorColor: EColors.primary,
            labelColor: EColors.textWhite,
            unselectedLabelColor: EColors.textSecondary,
            tabs: _columns
                .map(
                  (col) => Obx(() {
                    final count = ctrl.quotes.where((q) => q['status'] == col.status).length;
                    return Tab(text: '${col.label} ($count)');
                  }),
                )
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              children: _columns
                  .map((col) => _PipelineColumnWidget(ctrl: ctrl, column: col))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single column ────────────────────────────────────────────────────────

class _PipelineColumnWidget extends StatelessWidget {
  const _PipelineColumnWidget({required this.ctrl, required this.column});
  final AdminController ctrl;
  final _PipelineColumn column;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ColumnHeader(ctrl: ctrl, column: column),
        Expanded(
          child: _ColumnBody(ctrl: ctrl, column: column),
        ),
      ],
    );
  }
}

// ─── Column header ────────────────────────────────────────────────────────

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({required this.ctrl, required this.column});
  final AdminController ctrl;
  final _PipelineColumn column;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = ctrl.quotes.where((q) => q['status'] == column.status).length;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.1))),
        ),
        child: Text(
          '${column.label} ($count)',
          style: TextStyle(
            color: EColors.textSecondary,
            fontSize: ESizes.fontSizeSm,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    });
  }
}

// ─── Column body ──────────────────────────────────────────────────────────

class _ColumnBody extends StatelessWidget {
  const _ColumnBody({required this.ctrl, required this.column});
  final AdminController ctrl;
  final _PipelineColumn column;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = ctrl.quotes
          .where((q) => (q['status'] as String? ?? '') == column.status)
          .toList();

      if (items.isEmpty) {
        return Center(
          child: Text('None', style: TextStyle(color: EColors.textSecondary)),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final q = items[i];
          final id = q['id'] as String;
          return _PipelineCard(
            quote: q,
            onTap: () => AdminQuoteDetailDrawer.show(context, ctrl, id),
          );
        },
      );
    });
  }
}

// ─── Compact pipeline card ────────────────────────────────────────────────

class _PipelineCard extends StatelessWidget {
  const _PipelineCard({required this.quote, required this.onTap});
  final Map<String, dynamic> quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = quote['status'] as String? ?? '';
    final statusColor = _statusColor(status);
    final (statusLabel, _) = switch (status) {
      'active' => ('Active', null),
      'fully_paid' => ('Fully Paid', null),
      'deposit_paid' => ('Deposit Paid', null),
      _ => ('Pending', null),
    };
    final clientName = quote['client_name'] as String? ?? '';
    final businessName = quote['business_name'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
        decoration: BoxDecoration(
          color: EColors.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          border: Border.all(color: EColors.primary.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clientName,
              style: const TextStyle(
                color: EColors.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: ESizes.fontSizeSm,
              ),
            ),
            if (businessName.isNotEmpty)
              Text(
                businessName,
                style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
