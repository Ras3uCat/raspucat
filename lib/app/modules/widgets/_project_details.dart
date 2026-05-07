import 'package:raspucat/utils/constants/exports.dart';

class ProjectDetails extends StatelessWidget {
  const ProjectDetails({super.key, required this.project});

  final ProjectModel project;

  static const _backendTechs = {
    'Firebase',
    'Stripe',
    'Supabase',
    'Firebase Auth',
    'Supabase Auth',
    'Node',
    'PostgreSQL',
  };

  Color _tagColor(String tech) => _backendTechs.contains(tech) ? EColors.accent : EColors.primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (project.description.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
            child: Text(
              project.description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: EColors.textPrimary.withValues(alpha: 0.8)),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: ESizes.spaceBtwSections),
        ],
        if (project.technologies.isNotEmpty) ...[
          Wrap(
            spacing: ESizes.sm,
            runSpacing: ESizes.sm,
            alignment: WrapAlignment.center,
            children: project.technologies.map((tech) {
              final color = _tagColor(tech);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(
                  tech,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: ESizes.spaceBtwSections),
        ],
        if (project.githubUrl != null || project.liveUrl != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (project.githubUrl != null) ...[
                NeonButton(
                  neonColor: EColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.md),
                  onTap: () => EDeviceUtils.launchUrl(project.githubUrl!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FontAwesomeIcons.github, color: EColors.primary, size: ESizes.iconSm),
                      const SizedBox(width: ESizes.sm),
                      Text(
                        'SOURCE CODE',
                        style: TextStyle(
                          color: EColors.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          fontSize: ESizes.fontSizeSm,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ESizes.md),
              ],
              if (project.liveUrl != null)
                NeonButton(
                  neonColor: EColors.accent,
                  hoverColor: EColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.md),
                  onTap: () => EDeviceUtils.launchUrl(project.liveUrl!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, color: EColors.accent, size: ESizes.iconSm),
                      const SizedBox(width: ESizes.sm),
                      Text(
                        'VIEW LIVE',
                        style: TextStyle(
                          color: EColors.accent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          fontSize: ESizes.fontSizeSm,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        if (project.appStoreUrl != null || project.playStoreUrl != null) ...[
          const SizedBox(height: ESizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (project.appStoreUrl != null) ...[
                NeonButton(
                  neonColor: EColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.md),
                  onTap: () => EDeviceUtils.launchUrl(project.appStoreUrl!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FontAwesomeIcons.apple, color: EColors.primary, size: ESizes.iconSm),
                      const SizedBox(width: ESizes.sm),
                      Text(
                        'APP STORE',
                        style: TextStyle(
                          color: EColors.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          fontSize: ESizes.fontSizeSm,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ESizes.md),
              ],
              if (project.playStoreUrl != null)
                NeonButton(
                  neonColor: EColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.md),
                  onTap: () => EDeviceUtils.launchUrl(project.playStoreUrl!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.googlePlay,
                        color: EColors.primary,
                        size: ESizes.iconSm,
                      ),
                      const SizedBox(width: ESizes.sm),
                      Text(
                        'GOOGLE PLAY',
                        style: TextStyle(
                          color: EColors.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          fontSize: ESizes.fontSizeSm,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
