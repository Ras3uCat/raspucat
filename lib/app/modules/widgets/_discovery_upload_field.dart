// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:raspucat/utils/constants/exports.dart';

// File upload field for discovery form assets (logo, social share image).
// Calls [onUpload] with raw bytes + metadata; parent handles the actual upload.

class DiscoveryUploadField extends StatefulWidget {
  const DiscoveryUploadField({
    super.key,
    required this.label,
    required this.hint,
    required this.currentUrl,
    required this.accept,
    required this.onUpload,
  });

  final String label;
  final String hint;
  final String? currentUrl;
  final String accept; // e.g. 'image/png,image/jpeg,image/svg+xml'
  final Future<String?> Function(List<int> bytes, String mimeType, String fileName) onUpload;

  @override
  State<DiscoveryUploadField> createState() => _DiscoveryUploadFieldState();
}

class _DiscoveryUploadFieldState extends State<DiscoveryUploadField> {
  bool _uploading = false;
  String? _error;
  String? _url;

  @override
  void initState() {
    super.initState();
    _url = widget.currentUrl;
  }

  void _pick() {
    final input = html.FileUploadInputElement()..accept = widget.accept;
    input.click();
    input.onChange.listen((e) async {
      final file = input.files?.firstOrNull;
      if (file == null) return;
      setState(() {
        _uploading = true;
        _error = null;
      });
      try {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        final bytes = (reader.result as ByteBuffer).asUint8List();
        final result = await widget.onUpload(bytes, file.type, file.name);
        if (!mounted) return;
        setState(() {
          _uploading = false;
          if (result != null && !result.startsWith('ERR:')) {
            _url = result;
          } else {
            _error = result?.replaceFirst('ERR:', '') ?? 'Upload failed — try again';
          }
        });
      } catch (e) {
        if (mounted)
          setState(() {
            _uploading = false;
            _error = e.toString();
          });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: EColors.textSecondary.withValues(alpha: 0.5),
            fontSize: ESizes.fontSizeLabel,
          ),
        ),
        const SizedBox(height: 4),
        if (_url != null && _url!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
            child: Image.network(
              _url!,
              height: 72,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 6),
        ],
        GestureDetector(
          onTap: _uploading ? null : _pick,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
            decoration: BoxDecoration(
              color: EColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
              border: Border.all(color: EColors.primary.withValues(alpha: 0.3)),
            ),
            child: _uploading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: EColors.primary.withValues(alpha: 0.7),
                    ),
                  )
                : Text(
                    _url != null && _url!.isNotEmpty ? 'Replace' : 'Upload image',
                    style: TextStyle(
                      color: EColors.primary,
                      fontSize: ESizes.fontSizeSm,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.hint,
          style: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.3), fontSize: 11),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
        ],
      ],
    );
  }
}
