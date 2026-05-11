import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/data/models/app_project_model.dart';

class AdminAppProjectEmailProvisioned extends StatelessWidget {
  const AdminAppProjectEmailProvisioned({
    super.key,
    required this.project,
    required this.deprovisioning,
    required this.msg,
    required this.showConfirm,
    required this.onDeprovisionTap,
    required this.onDeprovisionConfirm,
    required this.onDeprovisionCancel,
  });

  final AppProject project;
  final bool deprovisioning;
  final String? msg;
  final bool showConfirm;
  final VoidCallback onDeprovisionTap;
  final VoidCallback onDeprovisionConfirm;
  final VoidCallback onDeprovisionCancel;

  static const _kMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime dt) => '${_kMonths[dt.month - 1]} ${dt.day}, ${dt.year}';

  @override
  Widget build(BuildContext context) {
    final email = project.aliasEmail!;
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
              icon: const Icon(Icons.copy_rounded, size: ESizes.iconXs, color: EColors.primary),
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
        if (project.emailProvisionedAt != null) ...[
          const SizedBox(height: 2),
          Text(
            'Provisioned ${_formatDate(project.emailProvisionedAt!)}',
            style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
          ),
        ],
        const SizedBox(height: ESizes.xs),
        if (!showConfirm)
          GestureDetector(
            onTap: deprovisioning ? null : onDeprovisionTap,
            child: Text(
              deprovisioning ? 'Deprovisioning…' : 'Deprovision',
              style: TextStyle(
                fontSize: ESizes.fontSizeLabel,
                color: deprovisioning ? EColors.softGrey : EColors.error,
              ),
            ),
          ),
        if (showConfirm)
          Row(
            children: [
              const Text(
                'Remove routing rule?',
                style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
              ),
              const SizedBox(width: ESizes.sm),
              GestureDetector(
                onTap: onDeprovisionConfirm,
                child: const Text(
                  'Yes',
                  style: TextStyle(color: EColors.error, fontSize: ESizes.fontSizeLabel),
                ),
              ),
              const SizedBox(width: ESizes.sm),
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
            padding: const EdgeInsets.only(top: ESizes.xs),
            child: Text(
              msg!,
              style: const TextStyle(fontSize: ESizes.fontSizeLabel, color: EColors.softGrey),
            ),
          ),
      ],
    );
  }
}
