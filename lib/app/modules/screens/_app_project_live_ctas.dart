import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:raspucat/utils/constants/colors.dart';
import 'package:raspucat/utils/constants/sizes.dart';

class LiveAppDownloadCtas extends StatelessWidget {
  const LiveAppDownloadCtas({super.key, this.appStoreUrl, this.playStoreUrl});

  final String? appStoreUrl;
  final String? playStoreUrl;

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ESizes.md,
      runSpacing: ESizes.sm,
      children: [
        if (appStoreUrl != null)
          _StoreButton(label: 'App Store', icon: Icons.apple, onTap: () => _open(appStoreUrl!)),
        if (playStoreUrl != null)
          _StoreButton(
            label: 'Google Play',
            icon: Icons.play_arrow_rounded,
            onTap: () => _open(playStoreUrl!),
          ),
      ],
    );
  }
}

class _StoreButton extends StatelessWidget {
  const _StoreButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.md),
        decoration: BoxDecoration(
          color: EColors.primary.withAlpha(26),
          border: Border.all(color: EColors.primary.withAlpha(153), width: 1),
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: ESizes.iconSm, color: EColors.primary),
            const SizedBox(width: ESizes.sm),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: ESizes.fontSizeSm,
                color: EColors.primary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
