import 'package:raspucat/app/controllers/admin_files_controller.dart';
import 'package:raspucat/utils/constants/exports.dart';

void _showImageLightbox(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.download_outlined,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AdminFilesSection extends StatelessWidget {
  const AdminFilesSection({super.key, required this.quoteId});
  final String quoteId;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(
      AdminFilesController(quoteId),
      tag: 'admin_files_$quoteId',
    );

    return Column(
      children: [
        _header(ctrl),
        Expanded(child: _body(ctrl)),
      ],
    );
  }

  Widget _header(AdminFilesController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.md, vertical: ESizes.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'FILES',
            style: TextStyle(
              color: EColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Obx(() => ctrl.isUploading.value
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      color: EColors.primary, strokeWidth: 1.5),
                )
              : GestureDetector(
                  onTap: ctrl.pickAndUpload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: ESizes.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: EColors.primary.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(ESizes.borderRadiusSM),
                      border: Border.all(
                          color: EColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.upload_outlined,
                            color: EColors.primary, size: 13),
                        const SizedBox(width: 4),
                        const Text('Upload',
                            style: TextStyle(
                                color: EColors.primary,
                                fontSize: ESizes.fontSizeLabel,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )),
          const SizedBox(width: ESizes.sm),
          Obx(() => ctrl.isLoading.value
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      color: EColors.primary, strokeWidth: 1.5),
                )
              : GestureDetector(
                  onTap: ctrl.loadFiles,
                  child: Icon(Icons.refresh,
                      color: EColors.textSecondary.withValues(alpha: 0.4),
                      size: 16),
                )),
        ],
      ),
    );
  }

  Widget _body(AdminFilesController ctrl) {
    return Obx(() {
      if (ctrl.isLoading.value && ctrl.files.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
              color: EColors.primary, strokeWidth: 2),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(ESizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ctrl.uploadError.value != null)
              _ErrorBanner(
                message: ctrl.uploadError.value!,
                onDismiss: () => ctrl.uploadError.value = null,
              ),
            _SectionLabel(label: 'From Raspucat (you)'),
            const SizedBox(height: ESizes.xs),
            if (ctrl.adminFiles.isEmpty)
              _EmptyHint('No files uploaded yet.')
            else
              ...ctrl.adminFiles.map((f) => _FileRow(
                    file: f,
                    onDownload: () => ctrl.downloadFile(f),
                    onDelete: () => ctrl.deleteFile(f),
                  )),
            const SizedBox(height: ESizes.lg),
            const _SectionLabel(label: 'From Client'),
            const SizedBox(height: ESizes.xs),
            if (ctrl.clientFiles.isEmpty)
              _EmptyHint('Client hasn\'t uploaded anything yet.')
            else
              ...ctrl.clientFiles.map((f) => _FileRow(
                    file: f,
                    onDownload: () => ctrl.downloadFile(f),
                  )),
          ],
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: TextStyle(
          color: EColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      );
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onDownload, this.onDelete});
  final AdminFile file;
  final VoidCallback onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final f = file.file;
    final thumbUrl = f.isImage ? file.signedUrl : null;
    return Container(
      margin: const EdgeInsets.only(bottom: ESizes.xs + 2),
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.sm, vertical: ESizes.xs + 2),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          if (thumbUrl != null)
            GestureDetector(
              onTap: () => _showImageLightbox(context, thumbUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.network(
                  thumbUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.image_outlined,
                      color: EColors.primary.withValues(alpha: 0.5), size: 16),
                ),
              ),
            )
          else
            Icon(f.fileIcon,
                color: EColors.primary.withValues(alpha: 0.5), size: 16),
          const SizedBox(width: ESizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: EColors.textWhite,
                        fontSize: ESizes.fontSizeLabel,
                        fontWeight: FontWeight.w500)),
                Text(f.formattedSize,
                    style: TextStyle(
                        color: EColors.textSecondary.withValues(alpha: 0.35),
                        fontSize: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDownload,
            child: Icon(Icons.download_outlined,
                color: EColors.primary.withValues(alpha: 0.6), size: 16),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: ESizes.xs),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.delete_outline,
                  color: EColors.textSecondary.withValues(alpha: 0.3),
                  size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
        child: Text(text,
            style: TextStyle(
                color: EColors.textSecondary.withValues(alpha: 0.35),
                fontSize: ESizes.fontSizeSm)),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: ESizes.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: ESizes.sm, vertical: ESizes.xs),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: Colors.redAccent, size: 14),
            const SizedBox(width: ESizes.xs),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: ESizes.fontSizeLabel))),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close,
                  color: Colors.redAccent, size: 14),
            ),
          ],
        ),
      );
}
