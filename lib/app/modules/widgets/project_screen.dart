import 'dart:async';
import 'package:raspucat/utils/constants/exports.dart';

class ProjectScreen extends StatefulWidget {
  final ProjectModel project;
  const ProjectScreen({super.key, required this.project});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen>
    with SingleTickerProviderStateMixin {
  final CarouselSliderController _carouselController = CarouselSliderController();
  late final AnimationController _enterCtrl;
  late final Animation<double> _carouselAnim;
  late final Animation<double> _detailsAnim;
  int _titleChars = 0;
  Timer? _typewriter;

  ProjectModel get project => widget.project;
  String get _fullTitle => project.title.toUpperCase();

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _carouselAnim = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.1, 0.65, curve: Curves.easeOut),
    );
    _detailsAnim = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _enterCtrl.forward();
    _typewriter = Timer.periodic(const Duration(milliseconds: 42), (t) {
      if (_titleChars >= _fullTitle.length) {
        t.cancel();
        return;
      }
      if (mounted) setState(() => _titleChars++);
    });
  }

  @override
  void dispose() {
    _typewriter?.cancel();
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleTitle = _fullTitle.substring(0, _titleChars);

    return Column(
      children: [
        SizedBox(height: ESizes.spaceBtwSections),

        SizedBox(height: ESizes.sm),

        // Typewriter title
        NeonText(
          isHeadline: true,
          neonColor: EColors.textPrimary.withValues(alpha: 0.5),
          text: visibleTitle.isEmpty ? '\u200B' : visibleTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: EColors.textPrimary,
          ),
        ),

        SizedBox(height: ESizes.spaceBtwSections),

        // Image carousel — slides up on entrance
        AnimatedBuilder(
          animation: _carouselAnim,
          child: project.imagePaths.isNotEmpty
              ? _buildImageCarousel(context)
              : _buildPlaceholder(context),
          builder: (_, child) => Transform.translate(
            offset: Offset(0, 30 * (1 - _carouselAnim.value)),
            child: Opacity(opacity: _carouselAnim.value, child: child),
          ),
        ),

        SizedBox(height: ESizes.spaceBtwSections),

        // Description, tech, buttons — fades in after carousel
        AnimatedBuilder(
          animation: _detailsAnim,
          child: _ProjectDetails(project: project),
          builder: (_, child) => Transform.translate(
            offset: Offset(0, 20 * (1 - _detailsAnim.value)),
            child: Opacity(opacity: _detailsAnim.value, child: child),
          ),
        ),

        SizedBox(height: ESizes.spaceBtwSections),
      ],
    );
  }

  Widget _buildImageCarousel(BuildContext context) {
    return Container(
      height: ESizes.imageSizeXl,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        border: Border.all(
          color: EColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: EColors.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        child: Stack(
          children: [
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: project.imagePaths.length,
              options: CarouselOptions(
                height: ESizes.imageSizeXl,
                viewportFraction: 1.0,
                enableInfiniteScroll: project.imagePaths.length > 1,
                autoPlay: false,
              ),
              itemBuilder: (context, index, _) => Stack(
                children: [
                  Image.asset(
                    project.imagePaths[index],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel: '${project.title} screenshot',
                  ),
                  Container(
                    color: EColors.primary.withValues(alpha: 0.08),
                  ),
                  if (project.imagePaths.length > 1)
                    Positioned(
                      top: ESizes.md,
                      right: ESizes.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ESizes.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: EColors.backgroundDark.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(
                            ESizes.borderRadiusMd,
                          ),
                          border: Border.all(
                            color: EColors.primary.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${index + 1} / ${project.imagePaths.length}',
                          style: TextStyle(
                            color: EColors.primary,
                            fontSize: ESizes.fontSizeLabel,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (project.imagePaths.length > 1) ...[
              Positioned(
                left: ESizes.sm,
                top: 0,
                bottom: 0,
                child: Center(
                  child: NeonButton(
                    padding: const EdgeInsets.all(ESizes.sm),
                    onTap: () => _carouselController.previousPage(),
                    child: Icon(
                      FontAwesomeIcons.chevronLeft,
                      color: EColors.primary,
                      size: ESizes.iconSm,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: ESizes.sm,
                top: 0,
                bottom: 0,
                child: Center(
                  child: NeonButton(
                    padding: const EdgeInsets.all(ESizes.sm),
                    onTap: () => _carouselController.nextPage(),
                    child: Icon(
                      FontAwesomeIcons.chevronRight,
                      color: EColors.primary,
                      size: ESizes.iconSm,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      height: ESizes.imageSizeLg,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EColors.primary.withValues(alpha: 0.2),
            EColors.secondary.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Icon(
          Icons.code,
          size: 80,
          color: EColors.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

// ─── Details block ────────────────────────────────────────────────────────────

class _ProjectDetails extends StatelessWidget {
  const _ProjectDetails({required this.project});

  final ProjectModel project;

  static const _backendTechs = {
    'Firebase', 'Stripe', 'Supabase',
    'Firebase Auth', 'Supabase Auth', 'Node', 'PostgreSQL',
  };

  Color _tagColor(String tech) =>
      _backendTechs.contains(tech) ? EColors.accent : EColors.primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (project.description.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
            child: Text(
              project.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: EColors.textPrimary.withValues(alpha: 0.8),
              ),
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
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                    width: 1,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: ESizes.lg,
                    vertical: ESizes.md,
                  ),
                  onTap: () => EDeviceUtils.launchUrl(project.githubUrl!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.github,
                        color: EColors.primary,
                        size: ESizes.iconSm,
                      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: ESizes.lg,
                    vertical: ESizes.md,
                  ),
                  onTap: () => EDeviceUtils.launchUrl(project.liveUrl!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_new,
                        color: EColors.accent,
                        size: ESizes.iconSm,
                      ),
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
      ],
    );
  }
}
