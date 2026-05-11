import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/data/models/app_project_model.dart';
import 'package:raspucat/utils/constants/colors.dart';
import 'package:raspucat/utils/constants/sizes.dart';
import 'package:raspucat/common/widgets/text/neon_text.dart';
import 'package:raspucat/routes/routes.dart';

class LaunchingPanel extends StatefulWidget {
  const LaunchingPanel({super.key, required this.project});

  final AppProject project;

  @override
  State<LaunchingPanel> createState() => _LaunchingPanelState();
}

class _LaunchingPanelState extends State<LaunchingPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          margin: const EdgeInsets.all(ESizes.lg),
          padding: const EdgeInsets.all(ESizes.xl),
          decoration: BoxDecoration(
            color: EColors.circuitSlate.withAlpha(204),
            border: Border.all(color: EColors.primary.withAlpha(77), width: 1),
            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BackLink(),
              const SizedBox(height: ESizes.lg),
              _CornerDivider(),
              const SizedBox(height: ESizes.xl),
              NeonText(
                text: project.name,
                neonColor: EColors.primary,
                isHeadline: true,
                style: const TextStyle(
                  fontSize: ESizes.fontSizeHeadline,
                  fontWeight: FontWeight.bold,
                  color: EColors.cyanTintedWhite,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: ESizes.md),
              FadeTransition(
                opacity: _blink,
                child: const Text(
                  '// LAUNCHING SOON',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: ESizes.fontSizeSm,
                    color: EColors.primary,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (project.description != null && project.description!.isNotEmpty) ...[
                const SizedBox(height: ESizes.lg),
                Text(
                  project.description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: ESizes.fontSizeMd,
                    color: EColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: ESizes.xl),
              _CornerDivider(),
              const SizedBox(height: ESizes.md),
              _StatusBadge(label: project.statusLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.offAllNamed(ERoutes.home),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_ios, size: ESizes.iconXs, color: EColors.textSecondary),
          SizedBox(width: ESizes.xs),
          Text(
            'raspucat.com',
            style: TextStyle(
              fontSize: ESizes.fontSizeLabel,
              color: EColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: ESizes.sm, height: 1, color: EColors.primary),
        Expanded(child: Container(height: 1, color: EColors.primary.withAlpha(51))),
        Container(width: ESizes.sm, height: 1, color: EColors.primary),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.xs),
      decoration: BoxDecoration(
        border: Border.all(color: EColors.primary.withAlpha(128)),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusXxl),
        color: EColors.primary.withAlpha(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: ESizes.fontSizeLabel,
          color: EColors.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
