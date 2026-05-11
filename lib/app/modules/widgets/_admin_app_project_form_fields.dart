import 'dart:math' as math;
import 'package:raspucat/utils/constants/exports.dart';

const _kStatuses = ['planning', 'development', 'beta', 'live', 'paused'];

String deriveAppProjectSlug(String name) {
  final stripped = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return stripped.substring(0, math.min(50, stripped.length));
}

class AdminAppProjectFormFields extends StatefulWidget {
  const AdminAppProjectFormFields({
    super.key,
    required this.name,
    required this.description,
    required this.techStack,
    required this.aliasEmail,
    required this.supabaseUrl,
    required this.repoUrl,
    required this.webUrl,
    required this.appStoreUrl,
    required this.playStoreUrl,
    required this.stripeUrl,
    required this.crashUrl,
    required this.status,
    required this.onStatusChanged,
  });

  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController techStack;
  final TextEditingController aliasEmail;
  final TextEditingController supabaseUrl;
  final TextEditingController repoUrl;
  final TextEditingController webUrl;
  final TextEditingController appStoreUrl;
  final TextEditingController playStoreUrl;
  final TextEditingController stripeUrl;
  final TextEditingController crashUrl;
  final String status;
  final ValueChanged<String> onStatusChanged;

  @override
  State<AdminAppProjectFormFields> createState() => _AdminAppProjectFormFieldsState();
}

class _AdminAppProjectFormFieldsState extends State<AdminAppProjectFormFields> {
  String _slugPreview = '';
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _slugPreview = deriveAppProjectSlug(widget.name.text);
    widget.name.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    widget.name.removeListener(_onNameChanged);
    super.dispose();
  }

  void _onNameChanged() {
    final slug = deriveAppProjectSlug(widget.name.text);
    if (slug != _slugPreview) setState(() => _slugPreview = slug);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminProjectField(controller: widget.name, label: 'Name *', required: true),
        if (_slugPreview.isNotEmpty) ...[
          const SizedBox(height: ESizes.xs),
          Text(
            '$_slugPreview@raspucat.com',
            style: const TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontSizeLabel,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Email will be provisioned after save',
            style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
          ),
        ],
        const SizedBox(height: ESizes.md),
        AdminProjectField(controller: widget.supabaseUrl, label: 'Supabase Project URL'),
        const SizedBox(height: ESizes.md),
        AdminProjectField(controller: widget.repoUrl, label: 'GitHub Repo URL'),
        const SizedBox(height: ESizes.lg),
        _AdvancedToggle(
          expanded: _showAdvanced,
          onToggle: () => setState(() => _showAdvanced = !_showAdvanced),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: ESizes.md),
          AdminProjectField(controller: widget.description, label: 'Description', maxLines: 3),
          const SizedBox(height: ESizes.md),
          AdminProjectStatusDropdown(value: widget.status, onChanged: widget.onStatusChanged),
          const SizedBox(height: ESizes.md),
          AdminProjectField(
            controller: widget.techStack,
            label: 'Tech Stack (comma-separated)',
            hint: 'Flutter, Supabase, GetX',
          ),
          const SizedBox(height: ESizes.md),
          AdminProjectField(controller: widget.webUrl, label: 'Web URL'),
          const SizedBox(height: ESizes.md),
          AdminProjectField(controller: widget.appStoreUrl, label: 'App Store URL'),
          const SizedBox(height: ESizes.md),
          AdminProjectField(controller: widget.playStoreUrl, label: 'Play Store URL'),
          const SizedBox(height: ESizes.md),
          AdminProjectField(controller: widget.stripeUrl, label: 'Stripe Dashboard URL'),
          const SizedBox(height: ESizes.md),
          AdminProjectField(controller: widget.crashUrl, label: 'Crash Report URL'),
        ],
        const SizedBox(height: ESizes.sm),
      ],
    );
  }
}

class _AdvancedToggle extends StatelessWidget {
  const _AdvancedToggle({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Row(
        children: [
          const Expanded(child: Divider(color: EColors.textSecondary, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESizes.sm),
            child: Text(
              expanded ? '// ADVANCED  ▴' : '// ADVANCED  ▾',
              style: const TextStyle(
                color: EColors.textSecondary,
                fontSize: ESizes.fontSizeLabel,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const Expanded(child: Divider(color: EColors.textSecondary, thickness: 0.5)),
        ],
      ),
    );
  }
}

// ─── Field primitives ─────────────────────────────────────────────────────────

class AdminProjectField extends StatelessWidget {
  const AdminProjectField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeSm),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
        hintStyle: TextStyle(
          color: EColors.textSecondary.withValues(alpha: 0.5),
          fontSize: ESizes.fontSizeSm,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          borderSide: const BorderSide(color: EColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          borderSide: const BorderSide(color: EColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          borderSide: const BorderSide(color: EColors.error),
        ),
        filled: true,
        fillColor: EColors.backgroundDark.withValues(alpha: 0.4),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }
}

class AdminProjectStatusDropdown extends StatelessWidget {
  const AdminProjectStatusDropdown({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: EColors.circuitSlate,
      style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeSm),
      decoration: InputDecoration(
        labelText: 'Status',
        labelStyle: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          borderSide: const BorderSide(color: EColors.primary),
        ),
        filled: true,
        fillColor: EColors.backgroundDark.withValues(alpha: 0.4),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
      ),
      items: _kStatuses
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(
                s[0].toUpperCase() + s.substring(1),
                style: const TextStyle(color: EColors.cyanTintedWhite),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

class AdminProjectSectionLabel extends StatelessWidget {
  const AdminProjectSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: EColors.primary,
        fontSize: ESizes.fontSizeLabel,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
