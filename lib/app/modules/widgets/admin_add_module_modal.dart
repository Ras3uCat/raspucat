import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/controllers/admin_catalog_controller.dart';
import 'package:raspucat/app/modules/widgets/admin_form_widgets.dart';

/// Modal for adding an a-la-carte module to an existing quote.
/// Charges the client's saved payment method immediately via admin-add-module.
class AdminAddModuleModal extends StatefulWidget {
  const AdminAddModuleModal({
    super.key,
    required this.ctrl,
    required this.catalogCtrl,
    required this.quoteId,
  });

  final AdminController ctrl;
  final AdminCatalogController catalogCtrl;
  final String quoteId;

  static void show(BuildContext context, AdminController ctrl, String quoteId) {
    final catalogCtrl = Get.find<AdminCatalogController>();
    final isWide = MediaQuery.of(context).size.width >= 600;
    final content = AdminAddModuleModal(
      ctrl: ctrl,
      catalogCtrl: catalogCtrl,
      quoteId: quoteId,
    );
    if (isWide) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: content,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => content,
      );
    }
  }

  @override
  State<AdminAddModuleModal> createState() => _AdminAddModuleModalState();
}

class _AdminAddModuleModalState extends State<AdminAddModuleModal> {
  String? _selectedModuleId;

  Set<String> _existingModuleIds() {
    final detail = widget.ctrl.quoteDetail[widget.quoteId];
    if (detail != null) {
      final raw = detail['module_ids'] as List<dynamic>? ?? [];
      return raw.map((e) => e.toString()).toSet();
    }
    final quote = widget.ctrl.quotes.firstWhereOrNull(
      (q) => q['id'] == widget.quoteId,
    );
    if (quote != null) {
      final raw = quote['module_ids'] as List<dynamic>? ?? [];
      return raw.map((e) => e.toString()).toSet();
    }
    return {};
  }

  static String _fmtCents(dynamic cents) {
    final c = cents as int? ?? 0;
    if (c == 0) return '\$0';
    final s = (c / 100).round().toString();
    if (s.length <= 3) return '\$$s';
    final buf = StringBuffer('\$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Future<void> _confirm() async {
    if (_selectedModuleId == null) return;
    await widget.ctrl.addModule(widget.quoteId, _selectedModuleId!);
    if (!mounted) return;
    final msg = widget.ctrl.quoteState[widget.quoteId]?['addModuleMsg'] as String?;
    if (msg != null && msg.startsWith('✅')) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = _existingModuleIds();
    final available = widget.catalogCtrl.modules
        .where((m) => !existing.contains((m as Map)['id']))
        .toList();

    final selectedModule = _selectedModuleId == null
        ? null
        : available.firstWhereOrNull(
            (m) => (m as Map)['id'] == _selectedModuleId,
          ) as Map?;

    return Obx(() {
      final state = widget.ctrl.quoteState[widget.quoteId] ?? {};
      final isLoading = state['addingModule'] as bool? ?? false;
      final msg = state['addModuleMsg'] as String?;

      return Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        decoration: BoxDecoration(
          color: EColors.backgroundDark,
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          border: Border.all(color: EColors.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminFormHeader(
              title: 'Add Module',
              onClose: () => Navigator.of(context).pop(),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ESizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (available.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: ESizes.lg),
                        child: Center(
                          child: Text(
                            'All modules are already included.',
                            style: TextStyle(
                              color: EColors.textSecondary,
                              fontSize: ESizes.fontSizeLabel,
                            ),
                          ),
                        ),
                      )
                    else
                      ...available.map((m) {
                        final mod = m as Map;
                        final id = mod['id'] as String;
                        final isSelected = id == _selectedModuleId;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedModuleId = id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            margin: const EdgeInsets.only(bottom: ESizes.sm),
                            padding: const EdgeInsets.all(ESizes.sm + 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? EColors.primary.withValues(alpha: 0.1)
                                  : EColors.primary.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                              border: Border.all(
                                color: isSelected
                                    ? EColors.primary.withValues(alpha: 0.7)
                                    : EColors.primary.withValues(alpha: 0.12),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mod['name'] as String? ?? id,
                                        style: TextStyle(
                                          color: isSelected ? EColors.primary : EColors.textWhite,
                                          fontWeight: FontWeight.w600,
                                          fontSize: ESizes.fontSizeLabel,
                                        ),
                                      ),
                                      if ((mod['description'] as String? ?? '').isNotEmpty)
                                        Text(
                                          mod['description'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: EColors.textSecondary,
                                            fontSize: ESizes.fontSizeLabel,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _fmtCents(mod['price']),
                                  style: const TextStyle(
                                    color: EColors.textWhite,
                                    fontWeight: FontWeight.w600,
                                    fontSize: ESizes.fontSizeLabel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    if (selectedModule != null) ...[
                      const SizedBox(height: ESizes.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'A la carte price: ${_fmtCents(selectedModule['price'])}',
                            style: TextStyle(
                              color: EColors.textSecondary,
                              fontSize: ESizes.fontSizeLabel,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (msg != null) ...[
                      const SizedBox(height: ESizes.sm),
                      Text(
                        msg,
                        style: TextStyle(
                          color: msg.startsWith('✅')
                              ? EColors.primary
                              : const Color(0xFFFF4D4D),
                          fontSize: ESizes.fontSizeLabel,
                        ),
                      ),
                    ],
                    if (available.isNotEmpty) ...[
                      const SizedBox(height: ESizes.md),
                      NeonButton(
                        width: double.infinity,
                        onTap: (_selectedModuleId == null || isLoading) ? null : _confirm,
                        neonColor: EColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: ESizes.md),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: EColors.primary,
                                  strokeWidth: 1.5,
                                ),
                              )
                            : Text(
                                selectedModule != null
                                    ? 'Charge ${_fmtCents(selectedModule['price'])} & Add Module'
                                    : 'Select a Module',
                                style: const TextStyle(
                                  color: EColors.textWhite,
                                  fontWeight: FontWeight.w600,
                                  fontSize: ESizes.fontSizeLabel,
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
