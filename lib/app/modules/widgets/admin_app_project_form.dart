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
  late final TextEditingController _aliasEmail;
  late final TextEditingController _supabaseUrl;
  late final TextEditingController _repoUrl;
  late final TextEditingController _webUrl;
  late final TextEditingController _appStoreUrl;
  late final TextEditingController _playStoreUrl;
  late final TextEditingController _stripeUrl;
  late final TextEditingController _crashUrl;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _techStack = TextEditingController(text: p?.techStack.join(', ') ?? '');
    _aliasEmail = TextEditingController(text: p?.aliasEmail ?? '');
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
    _name.dispose();
    _description.dispose();
    _techStack.dispose();
    _aliasEmail.dispose();
    _supabaseUrl.dispose();
    _repoUrl.dispose();
    _webUrl.dispose();
    _appStoreUrl.dispose();
    _playStoreUrl.dispose();
    _stripeUrl.dispose();
    _crashUrl.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ctrl = Get.find<AdminAppProjectsController>();
    final techList = _techStack.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _nullIfEmpty(_description.text),
      'status': _status,
      'tech_stack': techList,
      'alias_email': _nullIfEmpty(_aliasEmail.text),
      'supabase_url': _nullIfEmpty(_supabaseUrl.text),
      'repo_url': _nullIfEmpty(_repoUrl.text),
      'web_url': _nullIfEmpty(_webUrl.text),
      'app_store_url': _nullIfEmpty(_appStoreUrl.text),
      'play_store_url': _nullIfEmpty(_playStoreUrl.text),
      'stripe_dashboard_url': _nullIfEmpty(_stripeUrl.text),
      'crash_report_url': _nullIfEmpty(_crashUrl.text),
    };

    if (widget.initial == null) {
      await ctrl.createProject(data);
    } else {
      await ctrl.updateProject(
        widget.initial!.copyWith(
          name: data['name'] as String,
          description: data['description'] as String?,
          status: _status,
          techStack: techList,
          aliasEmail: data['alias_email'] as String?,
          supabaseUrl: data['supabase_url'] as String?,
          repoUrl: data['repo_url'] as String?,
          webUrl: data['web_url'] as String?,
          appStoreUrl: data['app_store_url'] as String?,
          playStoreUrl: data['play_store_url'] as String?,
          stripeDashboardUrl: data['stripe_dashboard_url'] as String?,
          crashReportUrl: data['crash_report_url'] as String?,
        ),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
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
            _FormHeader(isEdit: isEdit),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.md, ESizes.lg, ESizes.md),
                child: Form(
                  key: _formKey,
                  child: AdminAppProjectFormFields(
                    name: _name,
                    description: _description,
                    techStack: _techStack,
                    aliasEmail: _aliasEmail,
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
              isEdit: isEdit,
              onCancel: () => Navigator.of(context).pop(),
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

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

// ─── Actions ─────────────────────────────────────────────────────────────────

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
