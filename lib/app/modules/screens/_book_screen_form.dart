part of 'book_screen.dart';

// Body shown before slot is confirmed + contact details form.
class _BookBody extends StatefulWidget {
  const _BookBody({
    required this.bookingCtrl,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  final BookingController bookingCtrl;
  final RxBool isSubmitting;
  final RxnString errorMessage;
  final Future<void> Function({required String name, required String email, String? message}) onSubmit;

  @override
  State<_BookBody> createState() => _BookBodyState();
}

class _BookBodyState extends State<_BookBody> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.onSubmit(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().toLowerCase(),
      message: _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookingWidget(controller: widget.bookingCtrl),
        Obx(() {
          if (widget.bookingCtrl.selectedSlot.value == null) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: ESizes.lg),
              _ContactForm(
                formKey: _formKey,
                nameCtrl: _nameCtrl,
                emailCtrl: _emailCtrl,
                messageCtrl: _messageCtrl,
              ),
              const SizedBox(height: ESizes.md),
              Obx(() {
                if (widget.errorMessage.value != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: ESizes.sm),
                    child: Text(
                      widget.errorMessage.value!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: ESizes.fontSizeLabel),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              Obx(() => NeonButton(
                onTap: widget.isSubmitting.value ? null : _handleSubmit,
                padding: const EdgeInsets.symmetric(vertical: ESizes.md),
                child: widget.isSubmitting.value
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: EColors.primary),
                      )
                    : const Text(
                        'CONFIRM BOOKING',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: EColors.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          fontSize: ESizes.fontSizeSm,
                        ),
                      ),
              )),
            ],
          );
        }),
      ],
    );
  }
}

class _ContactForm extends StatelessWidget {
  const _ContactForm({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.messageCtrl,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController messageCtrl;

  static InputDecoration _dec(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
    hintStyle: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.4), fontSize: ESizes.fontSizeSm),
    filled: true,
    fillColor: EColors.primary.withValues(alpha: 0.05),
    contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm + 4),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
      borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
      borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.7), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
    errorStyle: const TextStyle(color: Colors.redAccent),
  );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nameCtrl,
            style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
            decoration: _dec('Your name', 'Jane Smith'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: ESizes.sm + 4),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
            decoration: _dec('Email address', 'jane@example.com'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
                  ? null
                  : 'Enter a valid email';
            },
          ),
          const SizedBox(height: ESizes.sm + 4),
          TextFormField(
            controller: messageCtrl,
            maxLines: 3,
            style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
            decoration: _dec('Message (optional)', 'Anything you'd like us to know before the call'),
          ),
        ],
      ),
    );
  }
}
