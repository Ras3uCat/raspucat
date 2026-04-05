import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import '_admin_delivery_steps.dart';
import '_admin_delivery_widgets.dart';

class AdminDeliverySection extends StatefulWidget {
  const AdminDeliverySection({
    super.key,
    required this.ctrl,
    required this.quoteId,
    required this.moduleIds,
  });

  final AdminController ctrl;
  final String quoteId;
  final List<String> moduleIds;

  @override
  State<AdminDeliverySection> createState() => _AdminDeliverySectionState();
}

class _AdminDeliverySectionState extends State<AdminDeliverySection> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.ctrl.fetchDeliveryProgress(widget.quoteId);
    if (!mounted) return;
    final rows = widget.ctrl.deliveryProgress[widget.quoteId];
    if (rows != null && rows.isEmpty) {
      await widget.ctrl.initDeliveryProgress(widget.quoteId, widget.moduleIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.ctrl.loadingDelivery.contains(widget.quoteId)) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 2),
          ),
        );
      }
      final rows = widget.ctrl.deliveryProgress[widget.quoteId] ?? [];
      final total = rows.length;
      final checked = rows.where((r) => r['checked'] == true).length;
      final done = total > 0 && checked == total;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(ESizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressHeader(checked: checked, total: total, done: done),
            const SizedBox(height: ESizes.md),
            ..._buildPhases(rows),
          ],
        ),
      );
    });
  }

  List<Widget> _buildPhases(List<Map<String, dynamic>> rows) {
    const phases = ['Setup', 'Deploy', 'Post-Deploy', 'QA', 'Handover'];
    final widgets = <Widget>[];
    for (final phase in phases) {
      final phaseRows = rows.where((r) {
        final def = deliveryStepByKey[r['step'] as String? ?? ''];
        return def?.phase == phase;
      }).toList();
      if (phaseRows.isEmpty) continue;
      widgets.add(PhaseLabel(phase));
      widgets.add(const SizedBox(height: 6));
      for (final row in phaseRows) {
        final def = deliveryStepByKey[row['step'] as String? ?? ''];
        if (def == null) continue;
        widgets.add(
          DeliveryStepRow(
            def: def,
            checked: row['checked'] == true,
            checkedBy: row['checked_by'] as String?,
            checkedAt: row['checked_at'] as String?,
            onToggle: def.isAuto
                ? null
                : (v) => widget.ctrl.toggleDeliveryStep(widget.quoteId, def.key, v),
          ),
        );
      }
      widgets.add(const SizedBox(height: ESizes.md));
    }
    return widgets;
  }
}
