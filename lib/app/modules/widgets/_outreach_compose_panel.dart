part of 'admin_outreach_widget.dart';

class _OutreachComposePanel extends StatefulWidget {
  const _OutreachComposePanel({required this.ctrl, required this.lead});
  final AdminOutreachController ctrl;
  final LeadModel lead;

  @override
  State<_OutreachComposePanel> createState() => _OutreachComposePanelState();
}

class _OutreachComposePanelState extends State<_OutreachComposePanel> {
  late final TextEditingController _subject;
  late final TextEditingController _body;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    final profile = _findProfile(widget.lead, widget.ctrl);
    _subject = TextEditingController(
      text:
          profile?.emailSubjectTemplate?.replaceAll('{COMPANY}', widget.lead.companyName) ??
          "Quick question about ${widget.lead.companyName}'s website",
    );
    _body = TextEditingController(text: _buildDefaultBody(widget.lead, widget.ctrl, profile));
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  static IndustryProfileModel? _findProfile(LeadModel lead, AdminOutreachController ctrl) =>
      ctrl.industryProfiles.cast<IndustryProfileModel?>().firstWhere(
        (p) =>
            p!.slug.toLowerCase() == lead.industry.toLowerCase() ||
            p.name.toLowerCase() == lead.industry.toLowerCase(),
        orElse: () => null,
      );

  String _buildDefaultBody(
    LeadModel lead,
    AdminOutreachController ctrl,
    IndustryProfileModel? profile,
  ) {
    final firstName = lead.decisionMakerName?.split(' ').first ?? '[Name]';
    final company = lead.companyName;

    if (profile?.emailBodyTemplate != null) {
      return profile!.emailBodyTemplate!
          .replaceAll('{FIRST_NAME}', firstName)
          .replaceAll('{COMPANY}', company);
    }

    final industryBlock = _buildIndustryBlock(company, lead.industry, profile);

    return '''Hi $firstName,

We are Cytarah and Ryan, co-owners of Raspucat. We build custom websites that combine modern design and smart functionality, tailored specifically to the businesses behind them.

$industryBlock

We've already put together a complimentary research package for your business containing a brand brief, competitor analysis, and brand alignment review tailored to $company.

If interested, we'd love to walk you through what we found. You can simply reply to this email, or book a free Website Audit & Strategy Session here:
{BOOKING_LINK}

You can also explore a live demo of what we build, the full experience and admin pages included:
{DEMO_LINK}''';
  }

  String _buildIndustryBlock(String company, String industry, IndustryProfileModel? profile) {
    final slug = profile?.slug.toLowerCase() ?? industry.toLowerCase();

    if (slug.contains('tattoo') || slug.contains('ink')) {
      return "We came across $company and were instantly impressed by your artists' work. "
          "We've been getting tattooed across three continents, so we have a real appreciation "
          "for the craft and we'd love to help your online presence showcase the talent in your shop.\n\n"
          "One thing that stood out: a booking system that lets clients submit requests and deposits "
          "directly to individual artists would be smoother for clients and create less admin for the "
          "shop, but that's just one way we could improve your day-to-day.";
    }

    final painPoint = (profile != null && profile.painPoints.isNotEmpty)
        ? profile.painPoints.first
        : '[Describe a specific pain point or opportunity you noticed for $company]';

    return "We came across $company and were impressed by what you're building. "
        "We'd love to help your online presence reflect the quality of your work.\n\n"
        "One thing that stood out: $painPoint — and that's just one way we could improve your day-to-day.";
  }

  void _saveDraft() {
    widget.ctrl.saveDraft(widget.lead.id, _subject.text.trim(), _toHtml(_body.text.trim()));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0E1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: EColors.primary.withAlpha(51)),
      ),
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.all(ESizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '// COMPOSE EMAIL',
                      style: TextStyle(
                        color: EColors.primary,
                        fontSize: ESizes.fontSizeLabel,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showPreview = !_showPreview),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showPreview ? EColors.primary.withAlpha(26) : Colors.transparent,
                        border: Border.all(color: EColors.primary.withAlpha(77)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _showPreview ? 'Edit' : 'Preview',
                        style: const TextStyle(
                          color: EColors.primary,
                          fontSize: ESizes.fontSizeLabel,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ESizes.lg),
              if (_showPreview)
                _ComposePreview(subject: _subject.text, body: _body.text)
              else
                _ComposeForm(subject: _subject, body: _body),
              const SizedBox(height: ESizes.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeSm),
                    ),
                  ),
                  const SizedBox(width: ESizes.lg),
                  Obx(
                    () => GestureDetector(
                      onTap: widget.ctrl.isLoading.value ? null : _saveDraft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ESizes.lg,
                          vertical: ESizes.sm,
                        ),
                        decoration: BoxDecoration(
                          color: EColors.primary.withAlpha(20),
                          border: Border.all(color: EColors.primary),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: widget.ctrl.isLoading.value
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: EColors.primary,
                                  strokeWidth: 1.5,
                                ),
                              )
                            : const Text(
                                'Save Draft',
                                style: TextStyle(
                                  color: EColors.primary,
                                  fontSize: ESizes.fontSizeSm,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
