import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/utils/constants/exports.dart';

class AdminDiscoveryDiffViewer extends StatefulWidget {
  const AdminDiscoveryDiffViewer({
    super.key,
    required this.changes,
    required this.quoteId,
    required this.ctrl,
  });
  final Map<String, dynamic> changes;
  final String quoteId;
  final AdminController ctrl;

  @override
  State<AdminDiscoveryDiffViewer> createState() => _AdminDiscoveryDiffViewerState();
}

class _AdminDiscoveryDiffViewerState extends State<AdminDiscoveryDiffViewer> {
  bool _rerunning = false;

  Future<void> _rerun() async {
    setState(() => _rerunning = true);
    try {
      await Supabase.instance.client.functions.invoke(
        'admin-update-quote',
        body: {
          'adminToken': widget.ctrl.adminToken,
          'quoteId': widget.quoteId,
          'action': 'rerun-brand-alignment',
        },
      );
      if (mounted) {
        Get.snackbar('Done', 'Brand alignment rerun started.', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Rerun failed: $e', snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      if (mounted) setState(() => _rerunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
        border: Border.all(color: EColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: EColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                ),
                child: const Text(
                  'Discovery Updated',
                  style: TextStyle(
                    color: EColors.gold,
                    fontSize: ESizes.fontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              _RerunButton(rerunning: _rerunning, onTap: _rerun),
            ],
          ),
          const SizedBox(height: ESizes.sm),
          ...widget.changes.entries.map(
            (e) => _DiffRow(field: e.key, diff: e.value as Map<String, dynamic>?),
          ),
        ],
      ),
    );
  }
}

class _RerunButton extends StatelessWidget {
  const _RerunButton({required this.rerunning, required this.onTap});
  final bool rerunning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: rerunning ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
        decoration: BoxDecoration(
          color: EColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
          border: Border.all(color: EColors.primary.withValues(alpha: 0.3)),
        ),
        child: rerunning
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: EColors.primary),
              )
            : const Text(
                'Rerun Brand Alignment',
                style: TextStyle(
                  color: EColors.primary,
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({required this.field, required this.diff});
  final String field;
  final Map<String, dynamic>? diff;

  @override
  Widget build(BuildContext context) {
    final was = diff?['was']?.toString() ?? '';
    final now = diff?['now']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field,
            style: const TextStyle(
              color: EColors.textWhite,
              fontSize: ESizes.fontSizeLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Was: $was',
                  style: TextStyle(
                    color: EColors.textSecondary.withValues(alpha: 0.55),
                    fontSize: ESizes.fontSizeLabel,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: ESizes.xs),
                child: Icon(Icons.arrow_forward, size: 12, color: EColors.primary),
              ),
              Expanded(
                child: Text(
                  'Now: $now',
                  style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminDiscoverySkipButton extends StatelessWidget {
  const AdminDiscoverySkipButton({super.key, required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
        decoration: BoxDecoration(
          color: EColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
          border: Border.all(color: EColors.gold.withValues(alpha: 0.4)),
        ),
        child: loading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: EColors.gold),
              )
            : const Text(
                'Skip Discovery',
                style: TextStyle(
                  color: EColors.gold,
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
