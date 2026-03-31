import 'package:raspucat/utils/constants/exports.dart';

class _Phase {
  const _Phase({
    required this.codename,
    required this.headline,
    required this.body,
    required this.icon,
    this.badge,
  });
  final String codename;
  final String headline;
  final String body;
  final IconData icon;
  final String? badge;
}

const _phases = [
  _Phase(codename: '01 / CONFIGURE', icon: Icons.tune_outlined,
    headline: 'Pick your plan. Build your stack.',
    body: 'Choose a preset plan or build from scratch. Toggle add-ons, watch the price update live. No surprises — your total is locked before you commit.'),
  _Phase(codename: '02 / DEPOSIT', icon: Icons.lock_outlined,
    headline: 'Secure your slot.',
    body: 'A deposit locks in your build. Stripe-powered — takes 30 seconds. Your remaining balance is charged only when the site is live.'),
  _Phase(codename: '03 / BUILD', icon: Icons.terminal_outlined,
    headline: 'We build. You watch.',
    body: 'Track your project stage, share assets, send messages, and see every update in real time — no chasing emails.',
    badge: 'Portal opens on deposit'),
  _Phase(codename: '04 / LAUNCH', icon: Icons.rocket_launch_outlined,
    headline: 'Live. Verified. Yours.',
    body: 'Final balance is charged only after you confirm the site is ready. Your domain, your brand, your business — online and running.'),
  _Phase(codename: '05 / EXPAND', icon: Icons.add_circle_outline,
    headline: 'Add features anytime.',
    body: 'Buy new modules — booking, AI chatbot, loyalty programs — straight from the portal. No new contracts. No waiting in a queue.'),
  _Phase(codename: '06 / OPERATE', icon: Icons.settings_outlined,
    headline: 'Stay running. Or take the keys.',
    body: 'Monthly management covers hosting, updates, and support. The handover package transfers everything — code, credentials, docs.'),
];

class HowItWorksSection extends StatefulWidget {
  const HowItWorksSection({super.key});
  @override
  State<HowItWorksSection> createState() => _HowItWorksSectionState();
}

class _HowItWorksSectionState extends State<HowItWorksSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _anims;
  bool _triggered = false;

  static const int _staggerMs = 80;
  static const int _durationMs = 420;
  static const int _totalMs = _staggerMs * 5 + _durationMs; // 5 = phases.length - 1

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );
    _anims = List.generate(_phases.length, (i) {
      final start = (_staggerMs * i) / _totalMs;
      final end = ((_staggerMs * i) + _durationMs) / _totalMs;
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isMobile = EDeviceUtils.isMobileWidth(width);
    final bool isTablet = width >= ESizes.mobile && width < ESizes.tablet;
    final animController = SectionAnimationController.instance;

    return SectionContainer(
      child: VisibilityDetector(
        key: const Key('how_it_works_section'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.05 && !_triggered) {
            _triggered = true;
            _ctrl.forward();
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOnView(
              id: 'hiw_heading',
              controller: animController,
              startOffset: const Offset(0, 25),
              child: FittedBox(
                child: NeonText(
                  text: EText.howItWorksHeading,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
            const SizedBox(height: ESizes.sm),
            AnimatedOnView(
              id: 'hiw_subtitle',
              controller: animController,
              startOffset: const Offset(0, 40),
              child: Text(
                EText.howItWorksSubLabel.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: EColors.textSecondary,
                  letterSpacing: 3.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: ESizes.spaceBtwSections),
            if (isMobile)
              _buildMobile()
            else if (isTablet)
              _buildTablet()
            else
              _buildRow(0, _phases.length),
          ],
        ),
      ),
    );
  }

  // Renders a horizontal strip of [count] phases starting at [from].
  Widget _buildRow(int from, int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(count, (i) {
        final gi = from + i;
        return Expanded(
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
                .animate(_anims[gi]),
            child: FadeTransition(
              opacity: _anims[gi],
              child: _DesktopPhaseItem(
                phase: _phases[gi],
                isFirst: i == 0,
                isLast: i == count - 1,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTablet() => Column(
    children: [
      _buildRow(0, 3),
      const SizedBox(height: ESizes.spaceBtwSections),
      _buildRow(3, 3),
    ],
  );

  Widget _buildMobile() {
    return Column(
      children: List.generate(_phases.length, (i) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
              .animate(_anims[i]),
          child: FadeTransition(
            opacity: _anims[i],
            child: Padding(
              padding: const EdgeInsets.only(bottom: ESizes.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    margin: const EdgeInsets.only(right: ESizes.md, top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: EColors.primary.withValues(alpha: 0.08),
                      border: Border.all(color: EColors.primary.withValues(alpha: 0.35)),
                    ),
                    child: Icon(_phases[i].icon, color: EColors.primary, size: ESizes.iconSm),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_phases[i].codename, style: TextStyle(
                          color: EColors.primary.withValues(alpha: 0.6),
                          fontSize: ESizes.fontSizeLabel, letterSpacing: 1.5)),
                        const SizedBox(height: 2),
                        Text(_phases[i].headline, style: TextStyle(
                          color: EColors.textWhite, fontSize: ESizes.fontSizeSm,
                          fontWeight: FontWeight.w600, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DesktopPhaseItem extends StatelessWidget {
  const _DesktopPhaseItem({
    required this.phase, required this.isFirst, required this.isLast,
  });
  final _Phase phase;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm),
      child: Column(
        children: [
          // Icon node + connector line
          Row(
            children: [
              Expanded(child: isFirst ? const SizedBox() : _DashLine()),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EColors.primary.withValues(alpha: 0.08),
                  border: Border.all(color: EColors.primary.withValues(alpha: 0.4)),
                ),
                child: Icon(phase.icon, color: EColors.primary, size: ESizes.iconMd),
              ),
              Expanded(child: isLast ? const SizedBox() : _DashLine()),
            ],
          ),
          const SizedBox(height: ESizes.md),
          // Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ESizes.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
              color: EColors.primary.withValues(alpha: 0.03),
              border: Border.all(color: EColors.primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phase.codename, style: TextStyle(
                  color: EColors.primary.withValues(alpha: 0.6),
                  fontSize: ESizes.fontSizeLabel, letterSpacing: 1.5)),
                const SizedBox(height: ESizes.sm),
                Text(phase.headline, style: TextStyle(
                  color: EColors.textWhite, fontSize: ESizes.fontSizeSm,
                  fontWeight: FontWeight.w600, height: 1.4)),
                const SizedBox(height: ESizes.sm),
                Text(phase.body, style: TextStyle(
                  color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel, height: 1.6)),
                if (phase.badge != null) ...[
                  const SizedBox(height: ESizes.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: EColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                      border: Border.all(color: EColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(phase.badge!, style: TextStyle(
                      color: EColors.accent, fontSize: ESizes.fontSizeLabel - 1, letterSpacing: 0.5)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashLine extends StatelessWidget {
  const _DashLine();
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 1, child: CustomPaint(painter: _DashPainter()));
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EColors.primary.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset((x + 4).clamp(0, size.width), 0), paint);
      x += 8;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
