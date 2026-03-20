import 'package:raspucat/utils/constants/exports.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = EDeviceUtils.isMobileWidth(width);

    return Container(
      height: ESizes.footerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: EColors.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Stack(
        children: [
          // Subtle top-edge glow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: EColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESizes.xl),
            child: isMobile ? _MobileFooter() : _DesktopFooter(),
          ),
        ],
      ),
    );
  }
}

// ─── Desktop (single row) ─────────────────────────────────────────────────────

class _DesktopFooter extends StatelessWidget {
  const _DesktopFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand mark + name
        M3OWBrandMark(size: 14, color: EColors.primary),
        const SizedBox(width: ESizes.sm),
        Text(
          EBrand.stylizedAppName,
          style: const TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),

        const Spacer(),

        // Center tagline
        Text(
          EBrand.voiceFooter,
          style: TextStyle(
            color: EColors.textSecondary.withValues(alpha: 0.6),
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 1.2,
          ),
        ),

        const Spacer(),

        // Copyright
        Text(
          '© ${DateTime.now().year} ${EBrand.creditCompact}',
          style: TextStyle(
            color: EColors.textSecondary.withValues(alpha: 0.5),
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── Mobile (two rows) ───────────────────────────────────────────────────────

class _MobileFooter extends StatelessWidget {
  const _MobileFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            M3OWBrandMark(size: 12, color: EColors.primary),
            const SizedBox(width: ESizes.xs + 2),
            Text(
              EBrand.stylizedAppName,
              style: const TextStyle(
                color: EColors.primary,
                fontSize: ESizes.fontSizeLabel,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${EBrand.voiceFooter}  ·  © ${DateTime.now().year}',
          style: TextStyle(
            color: EColors.textSecondary.withValues(alpha: 0.5),
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
