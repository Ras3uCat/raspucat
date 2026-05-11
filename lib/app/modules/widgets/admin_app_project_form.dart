import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/data/models/app_project_model.dart';
import 'package:raspucat/app/controllers/admin_app_projects_controller.dart';
import 'package:raspucat/app/modules/widgets/_admin_app_project_form_fields.dart';

class AdminAppProjectFormModal {
  static void show(BuildContext context, {AppProject? initial}) {
    showDialog<void>(
      context: context,
      builder: (_) => _AdminAppProjectFormDialog(initial: initial),
    );
  }
}

// ─── Dialog shell ─────────────────────────────────────────────────────────────

class _AdminAppProjectFormDialog extends StatefulWidget {
  const _AdminAppProjectFormDialog({this.initial});

  final AppProject? initial;

  @override
  State<_AdminAppProjectFormDialog> createState() => _AdminAppProjectFormDialogState();
}

class _AdminAppProjectFormDialogState extends State<_AdminAppProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _techStack;
  late final TextEditingController _supabaseUrl;
  late final TextEditingController _repoUrl;
  late final TextEditingController _webUrl;
  late final TextEditingController _appStoreUrl;
  late final TextEditingController _playStoreUrl;
  late final TextEditingController _stripeUrl;
  late final TextEditingController _crashUrl;
  late String _status;
  bool _saving = false;

  bool get _isCreate => widget.initial == null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _techStack = TextEditingController(text: p?.techStack.join(', ') ?? '');
    _supabaseUrl = TextEditingController(text: p?.supabaseUrl ?? '');
    _repoUrl = TextEditingController(text: p?.repoUrl ?? '');
    _webUrl = TextEditingController(text: p?.webUrl ?? '');
    _appStoreUrl = TextEditingController(text: p?.appStoreUrl ?? '');
    _playStoreUrl = TextEditingController(text: p?.playStoreUrl ?? '');
    _stripeUrl = TextEditingController(text: p?.stripeDashboardUrl ?? '');
    _crashUrl = TextEditingController(text: p?.crashReportUrl ?? '');
    _status = p?.status ?? 'development';
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _description,
      _techStack,
      _supabaseUrl,
      _repoUrl,
      _webUrl,
      _appStoreUrl,
      _playStoreUrl,
      _stripeUrl,
      _crashUrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ctrl = Get.find<AdminAppProjectsController>();

    if (_isCreate) {
      // Create with name only — email + web URL provisioned automatically
      final created = await ctrl.createProject({'name': _name.text.trim()});
      if (created != null) {
        if (mounted) Navigator.of(context).pop();
        await ctrl.provisionEmail(created.id, created.name);
      } else {
        if (mounted) setState(() => _saving = false);
      }
    } else {
      final techList = _techStack.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await ctrl.updateProject(
        widget.initial!.copyWith(
          name: _name.text.trim(),
          description: _nullIfEmpty(_description.text),
          status: _status,
          techStack: techList,
          supabaseUrl: _nullIfEmpty(_supabaseUrl.text),
          repoUrl: _nullIfEmpty(_repoUrl.text),
          webUrl: _nullIfEmpty(_webUrl.text),
          appStoreUrl: _nullIfEmpty(_appStoreUrl.text),
          playStoreUrl: _nullIfEmpty(_playStoreUrl.text),
          stripeDashboardUrl: _nullIfEmpty(_stripeUrl.text),
          crashReportUrl: _nullIfEmpty(_crashUrl.text),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: EColors.circuitSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.cardRadiusMd),
        side: BorderSide(color: EColors.primary.withValues(alpha: 0.25)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FormHeader(isEdit: !_isCreate),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.md, ESizes.lg, ESizes.md),
                child: Form(
                  key: _formKey,
                  child: _isCreate
                      ? AdminAppProjectCreateFields(name: _name)
                      : AdminAppProjectEditFields(
                          name: _name,
                          description: _description,
                          techStack: _techStack,
                          supabaseUrl: _supabaseUrl,
                          repoUrl: _repoUrl,
                          webUrl: _webUrl,
                          appStoreUrl: _appStoreUrl,
                          playStoreUrl: _playStoreUrl,
                          stripeUrl: _stripeUrl,
                          crashUrl: _crashUrl,
                          status: _status,
                          onStatusChanged: (v) => setState(() => _status = v),
                        ),
                ),
              ),
            ),
            _FormActions(
              saving: _saving,
              isEdit: !_isCreate,
              onCancel: () => Navigator.of(context).pop(),
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.isEdit});
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          Text(
            '// ${isEdit ? 'Edit Project' : 'New Project'}',
            style: const TextStyle(
              color: EColors.primary,
              fontSize: ESizes.fontSizeMd,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Actions ──────────────────────────────────────────────────────────────────

class _FormActions extends StatelessWidget {
  const _FormActions({
    required this.saving,
    required this.isEdit,
    required this.onCancel,
    required this.onSave,
  });

  final bool saving;
  final bool isEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: EColors.primary.withValues(alpha: 0.15))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: saving ? null : onCancel,
            child: Text('Cancel', style: TextStyle(color: EColors.textSecondary)),
          ),
          const SizedBox(width: ESizes.sm),
          NeonButton(
            onTap: saving ? null : onSave,
            padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
            enableOverlay: false,
            child: saving
                ? const SizedBox(
                    width: ESizes.iconSm,
                    height: ESizes.iconSm,
                    child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 2),
                  )
                : Text(
                    isEdit ? 'Save Changes' : 'Create',
                    style: const TextStyle(color: EColors.primary, fontSize: ESizes.fontSizeSm),
                  ),
          ),
        ],
      ),
    );
  }
}
