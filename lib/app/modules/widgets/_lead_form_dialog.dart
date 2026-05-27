part of 'admin_outreach_widget.dart';

void _showLeadFormDialog(BuildContext context, AdminOutreachController ctrl, LeadModel? lead) {
  showDialog(
    context: context,
    builder: (_) => _LeadFormDialog(ctrl: ctrl, lead: lead),
  );
}

class _LeadFormDialog extends StatefulWidget {
  const _LeadFormDialog({required this.ctrl, this.lead});
  final AdminOutreachController ctrl;
  final LeadModel? lead;

  @override
  State<_LeadFormDialog> createState() => _LeadFormDialogState();
}

class _LeadFormDialogState extends State<_LeadFormDialog> {
  late final TextEditingController _company;
  late final TextEditingController _industry;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _website;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _notes;
  String _source = 'manual';

  bool get _isEdit => widget.lead != null;

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    _company = TextEditingController(text: l?.companyName ?? '');
    _industry = TextEditingController(text: l?.industry ?? '');
    _city = TextEditingController(text: l?.city ?? '');
    _state = TextEditingController(text: l?.state ?? '');
    _website = TextEditingController(text: l?.website ?? '');
    _phone = TextEditingController(text: l?.phone ?? '');
    _email = TextEditingController(text: l?.email ?? '');
    _notes = TextEditingController(text: l?.notes ?? '');
    _source = l?.source ?? 'manual';
  }

  @override
  void dispose() {
    _company.dispose();
    _industry.dispose();
    _city.dispose();
    _state.dispose();
    _website.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (_company.text.trim().isEmpty || _industry.text.trim().isEmpty) return;
    final fields = {
      'company_name': _company.text.trim(),
      'industry': _industry.text.trim(),
      'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
      'state': _state.text.trim().isEmpty ? null : _state.text.trim(),
      'website': _website.text.trim().isEmpty ? null : _website.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'source': _source,
    };
    if (_isEdit) {
      widget.ctrl.updateLead(widget.lead!.id, fields);
    } else {
      widget.ctrl.createLead(fields);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0E1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: EColors.primary.withAlpha(51)),
      ),
      child: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ESizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? '// EDIT LEAD' : '// ADD LEAD',
                style: const TextStyle(
                  color: EColors.primary,
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: ESizes.lg),
              Row(
                children: [
                  Expanded(
                    child: _FormField(label: 'Company Name *', ctrl: _company),
                  ),
                  const SizedBox(width: ESizes.md),
                  Expanded(
                    child: _FormField(label: 'Industry *', ctrl: _industry),
                  ),
                ],
              ),
              const SizedBox(height: ESizes.md),
              Row(
                children: [
                  Expanded(
                    child: _FormField(label: 'City', ctrl: _city),
                  ),
                  const SizedBox(width: ESizes.md),
                  Expanded(
                    child: _FormField(label: 'State', ctrl: _state),
                  ),
                ],
              ),
              const SizedBox(height: ESizes.md),
              _FormField(label: 'Website', ctrl: _website),
              const SizedBox(height: ESizes.md),
              Row(
                children: [
                  Expanded(
                    child: _FormField(label: 'Phone', ctrl: _phone),
                  ),
                  const SizedBox(width: ESizes.md),
                  Expanded(
                    child: _FormField(label: 'Email', ctrl: _email),
                  ),
                ],
              ),
              const SizedBox(height: ESizes.md),
              _FormField(label: 'Notes', ctrl: _notes, maxLines: 3),
              const SizedBox(height: ESizes.md),
              _SourceDropdown(value: _source, onChanged: (v) => setState(() => _source = v)),
              const SizedBox(height: ESizes.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeSm),
                    ),
                  ),
                  const SizedBox(width: ESizes.lg),
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ESizes.lg,
                        vertical: ESizes.sm,
                      ),
                      decoration: BoxDecoration(
                        color: EColors.primary.withAlpha(20),
                        border: Border.all(color: EColors.primary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isEdit ? 'Save' : 'Add Lead',
                        style: const TextStyle(
                          color: EColors.primary,
                          fontSize: ESizes.fontSizeSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.label, required this.ctrl, this.maxLines = 1});
  final String label;
  final TextEditingController ctrl;
  final int maxLines;

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
          maxLines: maxLines,
          style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeSm),
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: EColors.primary.withAlpha(51)),
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

class _SourceDropdown extends StatelessWidget {
  const _SourceDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SOURCE',
          style: TextStyle(
            color: EColors.softGrey,
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: EColors.primary.withAlpha(51)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF0A0E1A),
              style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeSm),
              icon: const Icon(Icons.keyboard_arrow_down, color: EColors.primary, size: 16),
              items: const [
                DropdownMenuItem(value: 'manual', child: Text('Manual')),
                DropdownMenuItem(value: 'community', child: Text('Community')),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
