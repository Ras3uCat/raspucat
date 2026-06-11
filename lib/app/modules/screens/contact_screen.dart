import 'package:raspucat/app/controllers/booking_controller.dart';
import 'package:raspucat/app/controllers/contact_controller.dart';
import 'package:raspucat/app/modules/widgets/booking_widget.dart';
import 'package:raspucat/utils/constants/exports.dart';

part '_contact_form.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = SectionAnimationController.instance;
    final contact = ContactController.instance;

    return SectionContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedOnView(
            id: 'contact_heading',
            controller: ctrl,
            startOffset: const Offset(0, 25),
            child: FittedBox(
              child: NeonText(text: 'CONTACT', style: Theme.of(context).textTheme.headlineLarge),
            ),
          ),
          const SizedBox(height: ESizes.sm),
          AnimatedOnView(
            id: 'contact_subtitle',
            controller: ctrl,
            startOffset: const Offset(0, 40),
            child: Text(
              EText.contactSubLabel.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: EColors.textSecondary, letterSpacing: 3.0),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: ESizes.md),
          AnimatedOnView(
            id: 'contact_copy',
            controller: ctrl,
            startOffset: const Offset(0, 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                EText.contactCopy,
                style: TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontSizeMd,
                  height: 1.7,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: ESizes.spaceBtwSections),
          AnimatedOnView(
            id: 'contact_form',
            controller: ctrl,
            startOffset: const Offset(0, 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Obx(
                () => contact.isSubmitted.value
                    ? _SuccessMessage(meetUrl: contact.meetUrl.value)
                    : _ContactForm(contact: contact),
              ),
            ),
          ),
          const SizedBox(height: ESizes.spaceBtwSections),
          AnimatedOnView(
            id: 'contact_links',
            controller: ctrl,
            startOffset: const Offset(0, 15),
            child: _ContactLink(
              icon: FaIcon(FontAwesomeIcons.github, color: EColors.primary, size: ESizes.iconMd),
              label: 'Ras3uCat',
              url: 'https://github.com/Ras3uCat',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Success state ────────────────────────────────────────────────────────────

class _SuccessMessage extends StatelessWidget {
  const _SuccessMessage({this.meetUrl});
  final String? meetUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        color: EColors.primary.withValues(alpha: 0.04),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: EColors.primary, size: ESizes.iconLg),
          const SizedBox(height: ESizes.md),
          Text(
            'SIGNAL RECEIVED.',
            style: TextStyle(
              color: EColors.primary,
              fontSize: ESizes.fontSizeSm,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: ESizes.sm),
          Text(
            meetUrl != null
                ? 'Expect a response within one business day. Your call has been booked.'
                : 'Expect a response within one business day.',
            style: TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontSizeLabel,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          if (meetUrl != null) ...[
            const SizedBox(height: ESizes.md),
            GestureDetector(
              onTap: () => EDeviceUtils.launchUrl(meetUrl!),
              child: Text(
                'JOIN MEETING',
                style: TextStyle(
                  color: EColors.primary,
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  decoration: TextDecoration.underline,
                  decorationColor: EColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── GitHub link ──────────────────────────────────────────────────────────────

class _ContactLink extends StatefulWidget {
  const _ContactLink({required this.icon, required this.label, required this.url});
  final Widget icon;
  final String label;
  final String url;

  @override
  State<_ContactLink> createState() => _ContactLinkState();
}

class _ContactLinkState extends State<_ContactLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => EDeviceUtils.launchUrl(widget.url),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _hovered ? 1.0 : 0.55,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.icon,
              const SizedBox(width: ESizes.sm),
              Text(
                widget.label,
                style: const TextStyle(
                  color: EColors.primary,
                  fontSize: ESizes.fontSizeSm,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
