import 'dart:html' as html;
import 'package:flutter/services.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/utils/constants/exports.dart';

class AdminClientJsonDialog extends StatefulWidget {
  const AdminClientJsonDialog({
    super.key,
    required this.ctrl,
    required this.quoteId,
  });

  final AdminController ctrl;
  final String quoteId;

  static Future<void> show(
    BuildContext context,
    AdminController ctrl,
    String quoteId,
  ) =>
      showDialog<void>(
        context: context,
        builder: (_) =>
            AdminClientJsonDialog(ctrl: ctrl, quoteId: quoteId),
      );

  @override
  State<AdminClientJsonDialog> createState() => _AdminClientJsonDialogState();
}

class _AdminClientJsonDialogState extends State<AdminClientJsonDialog> {
  String? _json;
  String? _error;
  bool _loading = true;
  bool _copied = false;

  static const _manualFields = [
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'SUPABASE_SERVICE_ROLE_KEY',
    'STRIPE_SECRET_KEY',
    'STRIPE_WEBHOOK_SECRET',
    'SMTP_HOST',
    'SMTP_USER',
    'SMTP_PASS',
    'SITE_URL',
    'BRAND_COLOR_PRIMARY',
    'BRAND_COLOR_SECONDARY',
    'BRAND_FONT',
    'LOGO_URL',
  ];

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    try {
      final result = await widget.ctrl.generateClientJson(widget.quoteId);
      if (mounted) setState(() { _json = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _copy() async {
    if (_json == null) return;
    await Clipboard.setData(ClipboardData(text: _json!));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  void _download() {
    if (_json == null) return;
    final blob = html.Blob([_json!], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'client.json')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D0D1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        side: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Flexible(child: _buildBody()),
            if (_json != null) _buildChecklist(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.lg, vertical: ESizes.md),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: EColors.primary.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '// client.json',
            style: TextStyle(
              color: EColors.primary,
              fontSize: ESizes.fontSizeSm,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          if (_json != null) ...[
            GestureDetector(
              onTap: _download,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: ESizes.md, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: EColors.primary.withValues(alpha: 0.3)),
                  borderRadius:
                      BorderRadius.circular(ESizes.borderRadiusSM),
                ),
                child: Text(
                  'Download',
                  style: TextStyle(
                    color: EColors.primary,
                    fontSize: ESizes.fontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: ESizes.sm),
            GestureDetector(
              onTap: _copy,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: ESizes.md, vertical: 4),
                decoration: BoxDecoration(
                  color: _copied
                      ? EColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                      color: EColors.primary.withValues(alpha: 0.3)),
                  borderRadius:
                      BorderRadius.circular(ESizes.borderRadiusSM),
                ),
                child: Text(
                  _copied ? '✓ Copied' : 'Copy',
                  style: TextStyle(
                    color: EColors.primary,
                    fontSize: ESizes.fontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: ESizes.sm),
          ],
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.close,
                color: EColors.textSecondary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(ESizes.xl),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(ESizes.lg),
        child: Text(
          _error!,
          style: const TextStyle(
              color: Colors.redAccent, fontSize: ESizes.fontSizeSm),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESizes.md),
      child: SelectableText(
        _json!,
        style: const TextStyle(
          color: EColors.cyanTintedWhite,
          fontSize: 11,
          fontFamily: 'monospace',
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildChecklist() {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.03),
        border: Border(
          top: BorderSide(color: EColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILL IN BEFORE USE',
            style: TextStyle(
              color: EColors.primary.withValues(alpha: 0.5),
              fontSize: 9,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: _manualFields
                .map(
                  (f) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.25)),
                      borderRadius:
                          BorderRadius.circular(ESizes.borderRadiusSM),
                    ),
                    child: Text(
                      f,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
