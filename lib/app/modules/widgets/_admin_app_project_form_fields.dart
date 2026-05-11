import 'dart:math' as math;
import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/modules/widgets/_admin_project_field_primitives.dart';

String deriveAppProjectSlug(String name) {
  final stripped = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return stripped.substring(0, math.min(50, stripped.length));
}

// ─── Create form: name only ───────────────────────────────────────────────────

class AdminAppProjectCreateFields extends StatefulWidget {
  const AdminAppProjectCreateFields({super.key, required this.name});

  final TextEditingController name;

  @override
  State<AdminAppProjectCreateFields> createState() => _CreateFieldsState();
}

class _CreateFieldsState extends State<AdminAppProjectCreateFields> {
  String _slug = '';

  @override
  void initState() {
    super.initState();
    _slug = deriveAppProjectSlug(widget.name.text);
    widget.name.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    widget.name.removeListener(_onNameChanged);
    super.dispose();
  }

  void _onNameChanged() {
    final s = deriveAppProjectSlug(widget.name.text);
    if (s != _slug) setState(() => _slug = s);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminProjectField(controller: widget.name, label: 'App Name', required: true),
        if (_slug.isNotEmpty) ...[
          const SizedBox(height: ESizes.sm),
          _PreviewRow(icon: Icons.email_outlined, value: '$_slug@raspucat.com'),
          const SizedBox(height: ESizes.xs),
          _PreviewRow(icon: Icons.language_outlined, value: 'raspucat.com/$_slug'),
          const SizedBox(height: ESizes.xs),
          const Text(
            'Both will be created on save.',
            style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
          ),
        ],
        const SizedBox(height: ESizes.sm),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: ESizes.iconXs, color: EColors.primary),
        const SizedBox(width: ESizes.xs),
        Text(
          value,
          style: const TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLabel,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

// ─── Edit form: all fields ────────────────────────────────────────────────────

class AdminAppProjectEditFields extends StatefulWidget {
  const AdminAppProjectEditFields({
    super.key,
    required this.name,
    required this.description,
    required this.techStack,
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
  State<AdminAppProjectEditFields> createState() => _EditFieldsState();
}

class _EditFieldsState extends State<AdminAppProjectEditFields> {
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminProjectField(controller: widget.name, label: 'App Name', required: true),
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
