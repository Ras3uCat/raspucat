// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/utils/constants/exports.dart';

class AdminAssetUploadSection extends StatefulWidget {
  const AdminAssetUploadSection({
    super.key,
    required this.ctrl,
    required this.quoteId,
    required this.detail,
  });

  final AdminController ctrl;
  final String quoteId;
  final Map<String, dynamic> detail;

  @override
  State<AdminAssetUploadSection> createState() => _AdminAssetUploadSectionState();
}

class _AdminAssetUploadSectionState extends State<AdminAssetUploadSection> {
  bool _uploadingLogo = false;
  bool _uploadingOg = false;
  String? _logoError;
  String? _ogError;

  Future<void> _pick(String field) async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..click();

    await input.onChange.first;
    final file = input.files?.first;
    if (file == null) return;

    final isLogo = field == 'logo';
    setState(() {
      if (isLogo) {
        _uploadingLogo = true;
        _logoError = null;
      } else {
        _uploadingOg = true;
        _ogError = null;
      }
    });

    try {
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      await reader.onLoad.first;
      final b64 = (reader.result as String).split(',').last;

      await widget.ctrl.uploadAsset(widget.quoteId, field, b64, file.type, file.name);

      final deliveryStep = isLogo ? 'favicon_replaced' : 'og_image_set';
      await widget.ctrl.autoCheckDeliveryStep(widget.quoteId, deliveryStep);
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isLogo) {
            _logoError = e.toString();
          } else {
            _ogError = e.toString();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isLogo) {
            _uploadingLogo = false;
          } else {
            _uploadingOg = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = widget.detail['logo_url'] as String?;
    final ogUrl = widget.detail['og_image_url'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AssetRow(
          label: 'Logo',
          url: logoUrl,
          uploading: _uploadingLogo,
          error: _logoError,
          onUpload: () => _pick('logo'),
        ),
        const SizedBox(height: ESizes.sm),
        _AssetRow(
          label: 'OG Image',
          hint: '1200×630',
          url: ogUrl,
          uploading: _uploadingOg,
          error: _ogError,
          onUpload: () => _pick('og_image'),
        ),
      ],
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.label,
    required this.uploading,
    required this.onUpload,
    this.hint,
    this.url,
    this.error,
  });

  final String label;
  final String? hint;
  final String? url;
  final bool uploading;
  final String? error;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (url != null)
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: ESizes.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: EColors.primary.withValues(alpha: 0.2)),
              image: DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover),
            ),
          )
        else
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: ESizes.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: EColors.primary.withValues(alpha: 0.15)),
              color: EColors.primary.withValues(alpha: 0.04),
            ),
            child: Icon(Icons.image_outlined, size: 14, color: EColors.textSecondary),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      hint!,
                      style: TextStyle(
                        color: EColors.textSecondary.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                  if (url != null) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check_circle_outline, size: 12, color: EColors.primary),
                  ],
                ],
              ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
            ],
          ),
        ),
        MouseRegion(
          cursor: uploading ? MouseCursor.defer : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: uploading ? null : onUpload,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: EColors.primary.withValues(alpha: uploading ? 0.15 : 0.3),
                ),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
              ),
              child: uploading
                  ? SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: EColors.primary.withValues(alpha: 0.5),
                      ),
                    )
                  : Text(
                      url != null ? 'Replace' : 'Upload',
                      style: TextStyle(
                        color: EColors.primary.withValues(alpha: 0.8),
                        fontSize: ESizes.fontSizeLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
