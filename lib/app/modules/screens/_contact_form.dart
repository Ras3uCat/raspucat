part of 'contact_screen.dart';

class _ContactForm extends StatefulWidget {
  const _ContactForm({required this.contact});
  final ContactController contact;

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  BookingController? _bookingCtrl;

  static InputDecoration _decor(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: EColors.textSecondary,
      fontSize: ESizes.fontSizeLabel,
      letterSpacing: 1.0,
    ),
    filled: true,
    fillColor: EColors.primary.withValues(alpha: 0.03),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
      borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
      borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.6)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    errorStyle: const TextStyle(color: Colors.redAccent, fontSize: ESizes.fontSizeLabel),
  );

  void _onBookingToggle(bool value) {
    widget.contact.bookingEnabled.value = value;
    if (value) {
      _bookingCtrl ??= Get.put(BookingController(), tag: 'contact_booking');
      widget.contact.attachBookingController(_bookingCtrl!);
    } else {
      widget.contact.detachBookingController();
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.contact.detachBookingController();
    if (_bookingCtrl != null) {
      Get.delete<BookingController>(tag: 'contact_booking');
      _bookingCtrl = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.contact.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: widget.contact.nameCtrl,
            validator: widget.contact.validateRequired,
            style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
            decoration: _decor('Name'),
            cursorColor: EColors.primary,
          ),
          const SizedBox(height: ESizes.md),
          TextFormField(
            controller: widget.contact.emailCtrl,
            validator: widget.contact.validateEmail,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
            decoration: _decor('Email'),
            cursorColor: EColors.primary,
          ),
          const SizedBox(height: ESizes.md),
          TextFormField(
            controller: widget.contact.messageCtrl,
            validator: widget.contact.validateRequired,
            maxLines: 4,
            style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
            decoration: _decor('Message'),
            cursorColor: EColors.primary,
          ),
          const SizedBox(height: ESizes.md),
          Obx(
            () => SwitchListTile(
              value: widget.contact.bookingEnabled.value,
              onChanged: _onBookingToggle,
              title: const Text(
                'Schedule a call?',
                style: TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
              ),
              subtitle: const Text(
                'Pick a discovery call slot below.',
                style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
              ),
              activeColor: EColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: widget.contact.bookingEnabled.value && _bookingCtrl != null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: ESizes.md),
                    child: BookingWidget(controller: _bookingCtrl!),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: ESizes.sm),
          Obx(
            () => widget.contact.errorMessage.value != null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: ESizes.md),
                    child: Text(
                      widget.contact.errorMessage.value!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: ESizes.fontSizeLabel,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () => NeonButton(
              padding: const EdgeInsets.symmetric(vertical: ESizes.md),
              onTap: widget.contact.isSubmitting.value ? null : widget.contact.submit,
              child: widget.contact.isSubmitting.value
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: EColors.primary),
                    )
                  : Text(
                      widget.contact.hasBooking ? 'TRANSMIT + BOOK' : 'TRANSMIT',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: EColors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        fontSize: ESizes.fontSizeSm,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
