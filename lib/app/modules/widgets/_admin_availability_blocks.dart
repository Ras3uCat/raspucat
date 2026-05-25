part of 'admin_availability_widget.dart';

// ─── Upcoming blocks list ─────────────────────────────────────────────────────

class _AdminBlocksList extends StatelessWidget {
  const _AdminBlocksList({required this.ctrl});
  final AdminAvailabilityController ctrl;

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month}/${local.day}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (ctrl.blocks.isEmpty) {
      return Text(
        'No blocked times.',
        style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
      );
    }
    return Column(
      children: ctrl.blocks.map((block) {
        return Container(
          margin: const EdgeInsets.only(bottom: ESizes.sm),
          padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
          decoration: BoxDecoration(
            color: EColors.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
            border: Border.all(color: EColors.primary.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_fmt(block.from)} — ${_fmt(block.until)}',
                      style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
                    ),
                    if (block.reason != null && block.reason!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: ESizes.xs),
                        child: Text(
                          block.reason!,
                          style: const TextStyle(
                            color: EColors.textSecondary,
                            fontSize: ESizes.fontSizeLabel,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: ESizes.iconSm),
                color: Colors.redAccent.withValues(alpha: 0.7),
                tooltip: 'Remove block',
                onPressed: () => ctrl.unblockTime(block.id),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Block time form ──────────────────────────────────────────────────────────

class _AdminBlockForm extends StatefulWidget {
  const _AdminBlockForm({required this.ctrl});
  final AdminAvailabilityController ctrl;

  @override
  State<_AdminBlockForm> createState() => _AdminBlockFormState();
}

class _AdminBlockFormState extends State<_AdminBlockForm> {
  DateTime? _from;
  DateTime? _until;
  final _reasonCtrl = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isFrom}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isFrom) {
        _from = dt;
      } else {
        _until = dt;
      }
    });
  }

  String _fmtDt(DateTime? dt) {
    if (dt == null) return 'Select...';
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (_from == null || _until == null) return;
    await widget.ctrl.blockTime(_from!, _until!, _reasonCtrl.text.trim());
    if (widget.ctrl.errorMessage.value == null) {
      setState(() {
        _from = null;
        _until = null;
        _reasonCtrl.clear();
        _expanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(
                _expanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                color: EColors.primary,
                size: ESizes.iconSm,
              ),
              const SizedBox(width: ESizes.xs),
              const Text(
                'BLOCK A TIME RANGE',
                style: TextStyle(
                  color: EColors.primary,
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: ESizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _DateTimeButton(
                              label: 'FROM',
                              value: _fmtDt(_from),
                              onTap: () => _pickDateTime(isFrom: true),
                            ),
                          ),
                          const SizedBox(width: ESizes.sm),
                          Expanded(
                            child: _DateTimeButton(
                              label: 'UNTIL',
                              value: _fmtDt(_until),
                              onTap: () => _pickDateTime(isFrom: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ESizes.sm),
                      TextField(
                        controller: _reasonCtrl,
                        style: const TextStyle(
                          color: EColors.textWhite,
                          fontSize: ESizes.fontSizeSm,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Reason (optional)',
                          labelStyle: const TextStyle(
                            color: EColors.textSecondary,
                            fontSize: ESizes.fontSizeLabel,
                          ),
                          filled: true,
                          fillColor: EColors.primary.withValues(alpha: 0.03),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                            borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                            borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.6)),
                          ),
                        ),
                        cursorColor: EColors.primary,
                      ),
                      const SizedBox(height: ESizes.md),
                      Obx(
                        () => NeonButton(
                          onTap: (_from == null || _until == null || widget.ctrl.isLoading.value)
                              ? null
                              : _submit,
                          padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
                          child: const Text(
                            'BLOCK TIME',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: EColors.primary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              fontSize: ESizes.fontSizeSm,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: ESizes.sm),
        decoration: BoxDecoration(
          color: EColors.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          border: Border.all(color: EColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: EColors.textSecondary,
                fontSize: ESizes.fontSizeLabel,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: ESizes.xs),
            Text(
              value,
              style: const TextStyle(
                color: EColors.primary,
                fontSize: ESizes.fontSizeSm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
