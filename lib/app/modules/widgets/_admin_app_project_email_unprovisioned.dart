import 'package:raspucat/utils/constants/exports.dart';

class AdminAppProjectEmailUnprovisioned extends StatelessWidget {
  const AdminAppProjectEmailUnprovisioned({
    super.key,
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
                  color: EColors.cyanTintedWhite,
                  fontSize: ESizes.fontSizeLabel,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ESizes.sm,
                    vertical: ESizes.xs + 2,
                  ),
                  hintText: 'slug',
                  hintStyle: const TextStyle(color: EColors.softGrey),
                  suffixText: '@raspucat.com',
                  suffixStyle: const TextStyle(
                    color: EColors.softGrey,
                    fontSize: ESizes.fontSizeLabel,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                    borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                    borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: ESizes.sm),
            MouseRegion(
              cursor: provisioning ? MouseCursor.defer : SystemMouseCursors.click,
              child: GestureDetector(
                onTap: provisioning ? null : onProvision,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ESizes.sm + 4,
                    vertical: ESizes.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: EColors.primary.withValues(alpha: provisioning ? 0.2 : 0.5),
                    ),
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                  ),
                  child: provisioning
                      ? const SizedBox(
                          width: ESizes.iconSm,
                          height: ESizes.iconSm,
                          child: CircularProgressIndicator(
                            color: EColors.primary,
                            strokeWidth: 1.5,
                          ),
                        )
                      : const Text(
                          'Provision',
                          style: TextStyle(fontSize: ESizes.fontSizeLabel, color: EColors.primary),
                        ),
                ),
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
