import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';

class AdminLoginGate extends StatefulWidget {
  const AdminLoginGate({super.key, required this.ctrl});
  final AdminController ctrl;

  @override
  State<AdminLoginGate> createState() => _AdminLoginGateState();
}

class _AdminLoginGateState extends State<AdminLoginGate> {
  final _textCtrl = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _obscure = true;

  Future<void> _submit() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    final ok = await widget.ctrl.login(_textCtrl.text);
    if (mounted) setState(() { _loading = false; if (!ok) _error = 'Incorrect password.'; });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(ESizes.xl),
        decoration: BoxDecoration(
          color: EColors.backgroundDark,
          borderRadius: BorderRadius.circular(ESizes.borderRadiusXl),
          border: Border.all(color: EColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: EColors.primary.withValues(alpha: 0.1),
              blurRadius: 40,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeonText(
              text: 'Mission Control',
              neonColor: EColors.primary,
              isHeadline: false,
              style: const TextStyle(
                fontSize: ESizes.fontSizeLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ESizes.md),
            TextField(
              controller: _textCtrl,
              obscureText: _obscure,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: EColors.textWhite),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(
                  color: EColors.textSecondary.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: EColors.primary.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.7), width: 1.5),
                ),
                errorText: _error,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: EColors.textSecondary.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: ESizes.md),
            NeonButton(
              onTap: _loading ? null : _submit,
              neonColor: EColors.primary,
              padding: const EdgeInsets.symmetric(vertical: ESizes.sm + 4),
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: EColors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Enter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: EColors.textWhite,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
