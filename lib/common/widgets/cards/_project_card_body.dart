import 'package:raspucat/utils/constants/exports.dart';
import 'phone_mockup.dart';

class ProjectCardBody extends StatelessWidget {
  const ProjectCardBody({
    super.key,
    required this.project,
    required this.hovered,
    required this.onTap,
  });

  final ProjectModel project;
  final bool hovered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      highlightColor: Colors.transparent,
      splashColor: EColors.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ESizes.defaultSpace,
          vertical: ESizes.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageBlock(project: project, hovered: hovered, onTap: onTap),
            const SizedBox(height: ESizes.spaceBtwInputFields),
            NeonText(
              isHeadline: false,
              neonColor: EColors.textPrimary.withValues(alpha: 0.5),
              text: project.title.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: EColors.textPrimary),
            ),
            const SizedBox(height: ESizes.spaceBtwInputFields),
            _TechTags(technologies: project.technologies),
          ],
        ),
      ),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({
    required this.project,
    required this.hovered,
    required this.onTap,
  });

  final ProjectModel project;
  final bool hovered;
  final VoidCallback? onTap;

  Widget _buildImageContent() {
    if (project.imagePaths.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EColors.primary.withValues(alpha: 0.2),
              EColors.secondary.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.code,
            size: ESizes.imageSizeSm + ESizes.sm,
            color: EColors.primary.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    return Image.asset(
      project.imagePaths.first,
      fit: BoxFit.cover,
      semanticLabel: project.title,
      frameBuilder: (_, child, frame, sync) {
        if (sync || frame != null) return child;
        return const SkeletonShimmer();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isApp = project.type == ProjectType.app;
    return ClipRect(
      child: SizedBox(
        height: ESizes.imageSizeLg,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: isApp
                  ? UnconstrainedBox(
                      clipBehavior: Clip.hardEdge,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: kPhoneWidth,
                        height: ESizes.imageSizeLg * 2,
                        child: PhoneMockup(child: _buildImageContent()),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(
                        ESizes.borderRadiusLg,
                      ),
                      child: _buildImageContent(),
                    ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
                child: Container(
                  color: EColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
                  child: Container(
                    color: EColors.backgroundDark.withValues(alpha: 0.7),
                    child: Center(
                      child: NeonButton(
                        onTap: onTap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: ESizes.lg,
                          vertical: ESizes.md,
                        ),
                        child: Text(
                          'VIEW PROJECT',
                          style: TextStyle(
                            color: EColors.textWhite,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            fontSize: ESizes.fontSizeSm,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechTags extends StatelessWidget {
  const _TechTags({required this.technologies});

  final List<String> technologies;

  static const _backendTechs = {
    'Firebase',
    'Stripe',
    'Supabase',
    'Firebase Auth',
    'Supabase Auth',
    'Node',
    'PostgreSQL',
  };

  Color _tagColor(String tech) =>
      _backendTechs.contains(tech) ? EColors.accent : EColors.primary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ESizes.sm,
      runSpacing: ESizes.sm,
      children: technologies.take(3).map((tech) {
        final color = _tagColor(tech);
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ESizes.md - 4,
            vertical: ESizes.xs + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          ),
          child: Text(
            tech,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}
