import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';

/// Displays the provisioned @raspucat.com email for a quote.
/// If not yet provisioned: shows a slug input + "Provision" button.
/// If provisioned: shows the address with copy + deprovision option.
class AdminProvisionEmailSection extends StatefulWidget {
  const AdminProvisionEmailSection({
    super.key,
    required this.ctrl,
    required this.quoteId,
    required this.detail,
  });

  final AdminController ctrl;
  final String quoteId;
  final Map<String, dynamic> detail;

  @override
  State<AdminProvisionEmailSection> createState() => _AdminProvisionEmailSectionState();
}

class _AdminProvisionEmailSectionState extends State<AdminProvisionEmailSection> {
  late final TextEditingController _slugCtrl;
  bool _showDeprovisionConfirm = false;

  String get _clientName => widget.detail['client_name'] as String? ?? '';

  String get _businessName => widget.detail['business_name'] as String? ?? '';

  String _deriveSlug(String name) {
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return slug.length > 50 ? slug.substring(0, 50) : slug;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.detail['client_slug'] as String?;
    final slugSource = _businessName.isNotEmpty ? _businessName : _clientName;
    _slugCtrl = TextEditingController(text: existing ?? _deriveSlug(slugSource));
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provisioned = widget.detail['provisioned_email'] as String?;
    return Obx(() {
      final state = widget.ctrl.quoteState[widget.quoteId] ?? {};
      final provisioning = state['provisioningEmail'] == true;
      final deprovisioning = state['deprovisioningEmail'] == true;
      final msg = state['provisionEmailMsg'] as String?;

      if (provisioned != null) {
        return _ProvisionedView(
          email: provisioned,
          msg: msg,
          deprovisioning: deprovisioning,
          showConfirm: _showDeprovisionConfirm,
          onDeprovisionTap: () => setState(() => _showDeprovisionConfirm = true),
          onDeprovisionConfirm: () {
            setState(() => _showDeprovisionConfirm = false);
            widget.ctrl.deprovisionEmail(widget.quoteId);
          },
          onDeprovisionCancel: () => setState(() => _showDeprovisionConfirm = false),
        );
      }

      return _UnprovisionedView(
        slugCtrl: _slugCtrl,
        provisioning: provisioning,
        msg: msg,
        onProvision: () => widget.ctrl.provisionEmail(
          widget.quoteId,
          _clientName,
          slugOverride: _slugCtrl.text.trim().isEmpty ? null : _slugCtrl.text.trim(),
        ),
      );
    });
  }
}

class _ProvisionedView extends StatelessWidget {
  const _ProvisionedView({
    required this.email,
    required this.msg,
    required this.deprovisioning,
    required this.showConfirm,
    required this.onDeprovisionTap,
    required this.onDeprovisionConfirm,
    required this.onDeprovisionCancel,
  });

  final String email;
  final String? msg;
  final bool deprovisioning;
  final bool showConfirm;
  final VoidCallback onDeprovisionTap;
  final VoidCallback onDeprovisionConfirm;
  final VoidCallback onDeprovisionCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                email,
                style: const TextStyle(
                  color: EColors.primary,
                  fontSize: ESizes.fontSizeLabel,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 14, color: EColors.primary),
              tooltip: 'Copy',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: email));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        if (!showConfirm)
          GestureDetector(
            onTap: deprovisioning ? null : onDeprovisionTap,
            child: Text(
              deprovisioning ? 'Deprovisioning…' : 'Deprovision (manual early)',
              style: TextStyle(
                fontSize: ESizes.fontSizeLabel,
                color: deprovisioning ? EColors.softGrey : const Color(0xFFFF6B6B),
              ),
            ),
          ),
        if (showConfirm)
          Row(
            children: [
              const Text(
                'Remove this routing rule?',
                style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDeprovisionConfirm,
                child: const Text(
                  'Yes',
                  style: TextStyle(color: Color(0xFFFF6B6B), fontSize: ESizes.fontSizeLabel),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDeprovisionCancel,
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
                ),
              ),
            ],
          ),
        if (msg != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              msg!,
              style: const TextStyle(fontSize: ESizes.fontSizeLabel, color: EColors.softGrey),
            ),
          ),
      ],
    );
  }
}

class _UnprovisionedView extends StatelessWidget {
  const _UnprovisionedView({
    required this.slugCtrl,
    required this.provisioning,
    required this.msg,
    required this.onProvision,
  });

  final TextEditingController slugCtrl;
  final bool provisioning;
  final String? msg;
  final VoidCallback onProvision;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: slugCtrl,
                style: const TextStyle(
                  color: EColors.textWhite,
                  fontSize: ESizes.fontSizeLabel,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  hintText: 'slug',
                  hintStyle: const TextStyle(color: EColors.softGrey),
                  suffixText: '@raspucat.com',
                  suffixStyle: const TextStyle(
                    color: EColors.softGrey,
                    fontSize: ESizes.fontSizeLabel,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            MouseRegion(
              cursor: provisioning ? MouseCursor.defer : SystemMouseCursors.click,
              child: GestureDetector(
                onTap: provisioning ? null : onProvision,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: EColors.primary.withValues(alpha: provisioning ? 0.2 : 0.5),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    provisioning ? 'Provisioning…' : 'Provision',
                    style: TextStyle(
                      fontSize: ESizes.fontSizeLabel,
                      color: provisioning ? EColors.softGrey : EColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (msg != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              msg!,
              style: const TextStyle(fontSize: ESizes.fontSizeLabel, color: EColors.softGrey),
            ),
          ),
      ],
    );
  }
}
