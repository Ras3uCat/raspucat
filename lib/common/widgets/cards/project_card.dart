import 'package:raspucat/utils/constants/exports.dart';

class ProjectCard extends StatefulWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.index,
    required this.hoveredCardIndex,
    this.onTap,
    this.isSelected = true,
  });

  final ProjectModel project;
  final int index;
  final ValueNotifier<int?> hoveredCardIndex;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isSelected) _pulseController.repeat(reverse: true);
    widget.hoveredCardIndex.addListener(_onHoverChanged);
  }

  @override
  void didUpdateWidget(covariant ProjectCard old) {
    super.didUpdateWidget(old);
    if (widget.isSelected == old.isSelected) return;
    if (widget.isSelected) {
      // Only start pulsing if no card is currently hovered
      if (widget.hoveredCardIndex.value == null) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    widget.hoveredCardIndex.removeListener(_onHoverChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onHoverChanged() {
    if (!widget.isSelected) return;
    final hovered = widget.hoveredCardIndex.value;
    if (hovered == null) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }
  }

  // Glow rules (mirrors PlanCard):
  //   this card hovered          → 1.0 (full)
  //   another card hovered,
  //     this is selected         → 0.15 (dim hold)
  //   nothing hovered,
  //     this is selected         → pulse value
  //   nothing hovered,
  //     not selected             → 0.0
  double get _glowValue {
    final hovered = widget.hoveredCardIndex.value;
    if (hovered == widget.index) return 1.0;
    if (hovered != null && widget.isSelected) return 0.15;
    if (widget.isSelected) return _pulseAnim.value;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // Built once per setState — stable child for AnimatedBuilder
    final body = _CardBody(
      project: widget.project,
      hovered: _hovered,
      onTap: widget.onTap,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.hoveredCardIndex.value = widget.index;
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.hoveredCardIndex.value = null;
      },
      child: widget.isSelected
          // Selected: ValueListenableBuilder catches notifier changes (dim/undim),
          // AnimatedBuilder drives the pulse each frame.
          ? ValueListenableBuilder<int?>(
              valueListenable: widget.hoveredCardIndex,
              builder: (_, __, ___) => AnimatedBuilder(
                animation: _pulseAnim,
                child: body,
                builder: (_, child) =>
                    _CardShell(glow: _glowValue, child: child!),
              ),
            )
          // Non-selected: TweenAnimationBuilder smoothly interpolates hover in/out
          : TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _hovered ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: body,
              builder: (_, glow, child) =>
                  _CardShell(glow: glow, child: child!),
            ),
    );
  }
}

// ─── Shell ────────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  const _CardShell({required this.glow, required this.child});

  final double glow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderAlpha = (0.2 + 0.6 * glow).clamp(0.2, 0.8);

    return Container(
      width: ESizes.carouselWidth,
      margin: const EdgeInsets.symmetric(
        horizontal: ESizes.md,
        vertical: ESizes.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EColors.backgroundDark.withValues(alpha: glow > 0 ? 0.05 : 0.01),
            EColors.backgroundDark,
          ],
        ),
        border: Border.all(
          color: EColors.primary.withValues(alpha: borderAlpha),
          width: 1.0 + 0.5 * glow,
        ),
        boxShadow: [
          BoxShadow(
            color: EColors.primary.withValues(
              alpha: glow > 0 ? 0.22 * glow : 0.08,
            ),
            blurRadius: glow > 0 ? 24 * glow : 5,
            spreadRadius: glow > 0 ? 2 * glow : 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        child: Material(color: Colors.transparent, child: child),
      ),
    );
  }
}

// ─── Card body ────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({
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
        padding: const EdgeInsets.symmetric(horizontal: ESizes.defaultSpace, vertical: ESizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageBlock(project: project, hovered: hovered, onTap: onTap),
            const SizedBox(height: ESizes.spaceBtwInputFields),
            NeonText(
              isHeadline: false,
              neonColor: EColors.textPrimary.withValues(alpha: 0.5),
              text: project.title.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: EColors.textPrimary,
              ),
            ),
            const SizedBox(height: ESizes.spaceBtwInputFields),
            _TechTags(technologies: project.technologies),
          ],
        ),
      ),
    );
  }
}

// ─── Image block with hover overlay ──────────────────────────────────────────

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({
    required this.project,
    required this.hovered,
    required this.onTap,
  });

  final ProjectModel project;
  final bool hovered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ESizes.imageSizeLg,
      width: double.infinity,
      child: Stack(
        children: [
          // Base image / placeholder
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
              child: project.imagePaths.isNotEmpty
                  ? Image.asset(
                      project.imagePaths.first,
                      fit: BoxFit.cover,
                      semanticLabel: project.title,
                      frameBuilder: (_, child, frame, sync) {
                        if (sync || frame != null) return child;
                        return const SkeletonShimmer();
                      },
                    )
                  : Container(
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
                          size: 80,
                          color: EColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
            ),
          ),
          // Permanent cyan tint
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
              child: Container(
                color: EColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Hover CTA overlay
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
    );
  }
}

// ─── Tech tags with category colours ─────────────────────────────────────────

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
