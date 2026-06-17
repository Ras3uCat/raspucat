part of 'admin_outreach_widget.dart';

class _ComposeForm extends StatelessWidget {
  const _ComposeForm({required this.subject, required this.body});
  final TextEditingController subject;
  final TextEditingController body;

  static final _fieldBorder = OutlineInputBorder(
    borderSide: BorderSide(color: EColors.primary.withAlpha(51)),
    borderRadius: BorderRadius.circular(4),
  );
  static const _focusBorder = OutlineInputBorder(
    borderSide: BorderSide(color: EColors.primary),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUBJECT',
          style: TextStyle(
            color: EColors.softGrey,
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: subject,
          style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeSm),
          decoration: InputDecoration(
            enabledBorder: _fieldBorder,
            focusedBorder: _focusBorder,
            contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: ESizes.sm),
            isDense: true,
          ),
        ),
        const SizedBox(height: ESizes.md),
        const Text(
          'BODY',
          style: TextStyle(
            color: EColors.softGrey,
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: body,
          maxLines: 10,
          style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeSm),
          decoration: InputDecoration(
            hintText: 'Write your email here...',
            hintStyle: TextStyle(color: EColors.softGrey.withAlpha(128)),
            enabledBorder: _fieldBorder,
            focusedBorder: _focusBorder,
            contentPadding: const EdgeInsets.all(ESizes.sm),
          ),
        ),
      ],
    );
  }
}

class _ComposePreview extends StatelessWidget {
  const _ComposePreview({required this.subject, required this.body});
  final String subject;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(8),
        border: Border.all(color: EColors.primary.withAlpha(31)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject: $subject',
            style: const TextStyle(
              color: EColors.cyanTintedWhite,
              fontSize: ESizes.fontSizeSm,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESizes.md),
          Text(
            body.isEmpty ? '(no body)' : body,
            style: TextStyle(
              color: body.isEmpty ? EColors.softGrey : EColors.cyanTintedWhite,
              fontSize: ESizes.fontSizeSm,
            ),
          ),
          const SizedBox(height: ESizes.md),
          Text(
            'Branded HTML wrapper applied server-side.',
            style: TextStyle(
              color: EColors.softGrey.withAlpha(153),
              fontSize: ESizes.fontSizeLabel,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
