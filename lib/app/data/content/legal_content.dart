import 'package:raspucat/utils/constants/exports.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

// ─── Shared scaffold ──────────────────────────────────────────────────────────

class LegalPageScaffold extends StatelessWidget {
  const LegalPageScaffold({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: ESizes.lg,
              vertical: ESizes.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => Get.offAllNamed(ERoutes.home),
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: ESizes.iconSm, color: EColors.primary),
                    label: const Text(
                      'raspucat.com',
                      style: TextStyle(
                        color: EColors.primary,
                        fontSize: ESizes.fontSizeLabel,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: ESizes.lg),
                  NeonText(
                    text: title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: ESizes.xs),
                  Text(
                    lastUpdated,
                    style: TextStyle(
                      color: EColors.textSecondary.withValues(alpha: 0.55),
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
                  const SizedBox(height: ESizes.spaceBtwSections),
                  ...sections.map((s) => _SectionEntry(section: s)),
                  const SizedBox(height: ESizes.xl),
                  const SiteFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionEntry extends StatelessWidget {
  const _SectionEntry({required this.section});
  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.heading,
            style: const TextStyle(
              color: EColors.textWhite,
              fontSize: ESizes.fontSizeSm,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: ESizes.sm),
          SelectableText(
            section.body,
            style: TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontSizeLabel,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Terms & Conditions content ───────────────────────────────────────────────

const termsLastUpdated = 'Last updated: March 2026';

const termsContent = <LegalSection>[
  LegalSection(
    '1. Acceptance of Terms',
    'By accessing raspucat.com or engaging Ras3uCat LLC '
    'for any services, you agree to be bound by these Terms & Conditions. If you do not agree '
    'to these terms in full, please do not proceed with any purchase or inquiry.',
  ),
  LegalSection(
    '2. Services Provided',
    'Ras3uCat LLC provides custom web development services including website design and build, '
    'a private client portal for project tracking and communication, optional add-on modules '
    '(such as booking systems, AI chatbots, and loyalty programs), and ongoing site management plans. '
    'The exact scope of each engagement is confirmed in writing prior to deposit.',
  ),
  LegalSection(
    '3. Payment Terms',
    'A deposit is required to secure your build slot and initiate work. The deposit amount is '
    'shown at checkout before any charge is made. The remaining balance is invoiced only after '
    'you review and approve the completed site — no final payment is collected without your '
    'explicit confirmation. All payments are processed securely via Stripe and denominated in USD. '
    'You are responsible for any applicable sales or use taxes in your jurisdiction.',
  ),
  LegalSection(
    '4. Refund & Cancellation Policy',
    'Deposits are non-refundable once active development work has begun. If you cancel before '
    'work commences, a full refund of the deposit will be issued within 5 business days. '
    'If you cancel mid-project, a partial refund may be considered based on work completed, '
    'at our sole discretion. Because the final balance is only charged after your approval, '
    'no refund is available on the final payment once it has been collected.',
  ),
  LegalSection(
    '5. Intellectual Property',
    'Upon receipt of final payment in full, all custom design, code, and creative assets '
    'produced specifically for your project are assigned to you. Third-party libraries, '
    'frameworks, and fonts remain subject to their respective open-source or commercial licenses. '
    'Clients on a monthly management plan retain full access to and use of the live site; '
    'complete code and credential ownership transfers upon selection of the handover package. '
    'Ras3uCat LLC reserves the right to display completed work in its public portfolio unless '
    'you request otherwise in writing.',
  ),
  LegalSection(
    '6. Client Responsibilities',
    'You are responsible for supplying accurate and complete content, brand assets, copy, '
    'images, and any required third-party credentials (e.g. domain registrar access) within '
    'agreed timeframes. Review feedback must be provided within the agreed review window. '
    'Project delays resulting from late or incomplete client input do not constitute a breach '
    'by Ras3uCat LLC and may affect the delivery timeline.',
  ),
  LegalSection(
    '7. Limitation of Liability',
    'To the fullest extent permitted by applicable law, Ras3uCat LLC shall not '
    'be liable for any indirect, incidental, special, punitive, or consequential damages — '
    'including lost profits, lost data, or business interruption — arising from your use of '
    'or inability to use any delivered service or website. In all cases, our total aggregate '
    'liability to you shall not exceed the total amount paid by you for the specific project '
    'giving rise to the claim.',
  ),
  LegalSection(
    '8. Governing Law & Dispute Resolution',
    'These Terms are governed by and construed in accordance with the laws of the State of Texas, '
    'United States, without regard to its conflict of law provisions. You agree that any dispute '
    'arising out of or relating to these Terms or our services shall be resolved exclusively in '
    'the state or federal courts located in Williamson County, Texas, and you consent to personal '
    'jurisdiction in those courts.',
  ),
  LegalSection(
    '9. Changes to Terms',
    'We reserve the right to modify these Terms at any time. When changes are made, the "Last updated" '
    'date at the top of this page will be revised. Your continued use of our services following '
    'any update constitutes your acceptance of the revised Terms. We encourage you to review '
    'this page periodically.',
  ),
  LegalSection(
    '10. Contact',
    'If you have questions about these Terms & Conditions, please reach out:\n'
    'Email: meow@raspucat.com\n'
    'Ras3uCat LLC — Liberty Hill, Texas, USA',
  ),
];

// ─── Privacy Policy content ───────────────────────────────────────────────────

const privacyLastUpdated = 'Last updated: March 2026';

const privacyContent = <LegalSection>[
  LegalSection(
    '1. What We Collect',
    'When you submit an inquiry, configure a plan, or use the client portal, we may collect:\n'
    '• Contact information: name and email address\n'
    '• Project details you provide during onboarding\n'
    '• Payment information — collected and tokenized directly by Stripe; we never store raw card numbers\n'
    '• Portal activity: messages, uploaded files, and project stage interactions stored in Supabase\n'
    '• Basic usage data such as page visits, collected anonymously',
  ),
  LegalSection(
    '2. How We Use Your Information',
    'We use the information we collect solely to:\n'
    '• Deliver, manage, and communicate about your project\n'
    '• Process payments and send receipts via Stripe\n'
    '• Grant and maintain your access to the client portal\n'
    '• Respond to support requests and questions\n'
    'We do not sell, rent, or share your personal data with third parties for advertising '
    'or marketing purposes.',
  ),
  LegalSection(
    '3. Third-Party Services',
    'We rely on the following trusted third-party providers to operate our service:\n'
    '• Stripe — payment processing. Stripe\'s privacy policy: stripe.com/privacy\n'
    '• Supabase — secure database, file storage, and authentication. supabase.com/privacy\n'
    '• Cloud hosting providers — for site delivery, DNS, and infrastructure\n'
    'Each provider operates under its own privacy policy and data processing agreements. '
    'We select providers that meet industry-standard security requirements.',
  ),
  LegalSection(
    '4. Data Retention',
    'We retain your personal and project data for as long as your engagement with Ras3uCat LLC '
    'is active and for up to 3 years thereafter for business record-keeping and dispute resolution purposes. '
    'Payment records may be retained longer as required by applicable tax law. '
    'You may request early deletion of your data at any time — see Section 5.',
  ),
  LegalSection(
    '5. Your Rights',
    'You have the right to:\n'
    '• Access the personal data we hold about you\n'
    '• Request correction of inaccurate or incomplete data\n'
    '• Request deletion of your data, subject to legal retention obligations\n'
    '• Withdraw consent for communications at any time\n'
    'To exercise any of these rights, contact us at meow@raspucat.com. '
    'We will respond within 30 days. If you are a California resident, you may have '
    'additional rights under the California Consumer Privacy Act (CCPA).',
  ),
  LegalSection(
    '6. Cookies',
    'This site uses only essential cookies required for authentication and session management — '
    'for example, keeping you logged in to the client portal. We do not use third-party '
    'advertising cookies, cross-site tracking, or analytics cookies that identify you personally. '
    'You may disable cookies in your browser settings, but doing so may affect portal functionality.',
  ),
  LegalSection(
    '7. Contact',
    'For any privacy-related questions, data requests, or concerns, please contact us:\n'
    'Email: meow@raspucat.com\n'
    'Ras3uCat LLC — Liberty Hill, Texas, USA',
  ),
];
