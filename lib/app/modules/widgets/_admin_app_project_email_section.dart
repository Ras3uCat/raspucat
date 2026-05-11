import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/data/models/app_project_model.dart';
import 'package:raspucat/app/controllers/admin_app_projects_controller.dart';
import 'package:raspucat/app/modules/widgets/_admin_app_project_form_fields.dart';
import 'package:raspucat/app/modules/widgets/_admin_app_project_email_provisioned.dart';
import 'package:raspucat/app/modules/widgets/_admin_app_project_email_unprovisioned.dart';

class AdminAppProjectEmailSection extends StatefulWidget {
  const AdminAppProjectEmailSection({super.key, required this.project});

  final AppProject project;

  @override
  State<AdminAppProjectEmailSection> createState() => _AdminAppProjectEmailSectionState();
}

class _AdminAppProjectEmailSectionState extends State<AdminAppProjectEmailSection> {
  late final TextEditingController _slugCtrl;
  bool _showDeprovisionConfirm = false;

  AdminAppProjectsController get _ctrl => Get.find<AdminAppProjectsController>();

  @override
  void initState() {
    super.initState();
    _slugCtrl = TextEditingController(text: deriveAppProjectSlug(widget.project.name));
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: EColors.textSecondary, thickness: 0.15),
        const SizedBox(height: ESizes.sm),
        const Text(
          '// EMAIL',
          style: TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLabel,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        Obx(() {
          final provisioning = _ctrl.provisioningIds.contains(widget.project.id);
          final msg = _ctrl.provisionMessages[widget.project.id];

          if (widget.project.emailProvisioned) {
            return AdminAppProjectEmailProvisioned(
              project: widget.project,
              deprovisioning: provisioning,
              msg: msg,
              showConfirm: _showDeprovisionConfirm,
              onDeprovisionTap: () => setState(() => _showDeprovisionConfirm = true),
              onDeprovisionConfirm: () {
                setState(() => _showDeprovisionConfirm = false);
                _ctrl.deprovisionEmail(widget.project.id);
              },
              onDeprovisionCancel: () => setState(() => _showDeprovisionConfirm = false),
            );
          }

          return AdminAppProjectEmailUnprovisioned(
            slugCtrl: _slugCtrl,
            provisioning: provisioning,
            msg: msg,
            onProvision: () => _ctrl.provisionEmail(
              widget.project.id,
              widget.project.name,
              slugOverride: _slugCtrl.text.trim().isEmpty ? null : _slugCtrl.text.trim(),
            ),
          );
        }),
      ],
    );
  }
}
