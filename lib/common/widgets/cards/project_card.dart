import 'package:raspucat/common/widgets/cards/_project_card_body.dart';
import 'package:raspucat/common/widgets/cards/_project_card_shell.dart';
import 'package:raspucat/common/widgets/cursor_overlay.dart';
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

class _ProjectCardState extends State<ProjectCard> with SingleTickerProviderStateMixin {
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
    _pulseAnim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    if (widget.isSelected) _pulseController.repeat(reverse: true);
    widget.hoveredCardIndex.addListener(_onHoverChanged);
  }

  @override
  void didUpdateWidget(covariant ProjectCard old) {
    super.didUpdateWidget(old);
    if (widget.isSelected == old.isSelected) return;
    if (widget.isSelected) {
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

  // Glow rules:
  //   this card hovered              → 1.0 (full)
  //   another card hovered, selected → 0.15 (dim hold)
  //   nothing hovered, selected      → pulse value
  //   nothing hovered, not selected  → 0.0
  double get _glowValue {
    final hovered = widget.hoveredCardIndex.value;
    if (hovered == widget.index) return 1.0;
    if (hovered != null && widget.isSelected) return 0.15;
    if (widget.isSelected) return _pulseAnim.value;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final body = ProjectCardBody(project: widget.project, hovered: _hovered, onTap: widget.onTap);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.hoveredCardIndex.value = widget.index;
        // Priority 2: expand cursor ring on card hover.
        if (kIsWeb) CursorState.isInteractive.value = true;
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.hoveredCardIndex.value = null;
        if (kIsWeb) CursorState.isInteractive.value = false;
      },
      child: widget.isSelected
          ? ValueListenableBuilder<int?>(
              valueListenable: widget.hoveredCardIndex,
              builder: (_, __, ___) => AnimatedBuilder(
                animation: _pulseAnim,
                child: body,
                builder: (_, child) => ProjectCardShell(glow: _glowValue, child: child!),
              ),
            )
          : TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _hovered ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: body,
              builder: (_, glow, child) => ProjectCardShell(glow: glow, child: child!),
            ),
    );
  }
}
