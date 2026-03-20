import 'package:raspucat/app/controllers/portal_files_controller.dart';
import 'package:raspucat/app/data/models/portal_file_model.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PortalFilesView extends StatelessWidget {
  const PortalFilesView({super.key, required this.quoteId});
  final String quoteId;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(PortalFilesController(quoteId), tag: quoteId);
    return Column(
      children: [
        _FilesHeader(ctrl: ctrl),
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                    color: EColors.primary, strokeWidth: 2),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(ESizes.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ctrl.uploadError.value != null)
                      _ErrorBanner(
                          message: ctrl.uploadError.value!,
                          onDismiss: () => ctrl.uploadError.value = null),
                    _SectionHeading(
                      label: 'Your Uploads',
                      action: _UploadButton(ctrl: ctrl),
                    ),
                    const SizedBox(height: ESizes.md),
                    if (ctrl.clientFiles.isEmpty)
                      _EmptyHint(
                          'No files uploaded yet. Send us your logos, copy, or brand assets.')
                    else
                      ...ctrl.clientFiles.map((f) => _FileRow(
                            file: f,
                            onDownload: () => ctrl.downloadFile(f),
                            onDelete: () => ctrl.deleteFile(f),
                          )),
                    const SizedBox(height: ESizes.xl),
                    const _SectionHeading(label: 'From Raspucat'),
                    const SizedBox(height: ESizes.md),
                    if (ctrl.adminFiles.isEmpty)
                      _EmptyHint('No files from the team yet.')
                    else
                      ...ctrl.adminFiles.map((f) => _FileRow(
                            file: f,
                            onDownload: () => ctrl.downloadFile(f),
                          )),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _FilesHeader extends StatelessWidget {
  const _FilesHeader({required this.ctrl});
  final PortalFilesController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.xl, vertical: ESizes.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, color: EColors.primary, size: 18),
          const SizedBox(width: ESizes.sm),
          const Text('Files',
              style: TextStyle(
                  color: EColors.textWhite,
                  fontSize: ESizes.fontSizeLg,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4)),
          const Spacer(),
          Obx(() => ctrl.isLoading.value
              ? const SizedBox.shrink()
              : IconButton(
                  icon: Icon(Icons.refresh,
                      color: EColors.textSecondary.withValues(alpha: 0.4),
                      size: 18),
                  onPressed: ctrl.loadFiles,
                )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section heading
// ---------------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label, this.action});
  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: EColors.textSecondary.withValues(alpha: 0.4),
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        if (action != null) ...[const Spacer(), action!],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Upload button
// ---------------------------------------------------------------------------

class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.ctrl});
  final PortalFilesController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
          onTap: ctrl.isUploading.value ? null : ctrl.pickAndUpload,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: ESizes.md, vertical: ESizes.xs + 2),
            decoration: BoxDecoration(
              color: EColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
              border: Border.all(
                  color: EColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ctrl.isUploading.value)
                  const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                        color: EColors.primary, strokeWidth: 1.5),
                  )
                else
                  const Icon(Icons.upload_outlined,
                      color: EColors.primary, size: 15),
                const SizedBox(width: ESizes.xs),
                Text(
                  ctrl.isUploading.value ? 'Uploading…' : 'Upload File',
                  style: const TextStyle(
                      color: EColors.primary,
                      fontSize: ESizes.fontSizeLabel,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ));
  }
}

// ---------------------------------------------------------------------------
// File row
// ---------------------------------------------------------------------------

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
                  child:
                      const Icon(Icons.close, color: Colors.white, size: 16),
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

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onDownload, this.onDelete});
  final PortalFile file;
  final VoidCallback onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final thumbUrl = file.isImage ? file.signedUrl : null;
    return Container(
      margin: const EdgeInsets.only(bottom: ESizes.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.md, vertical: ESizes.sm + 2),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          if (thumbUrl != null)
            GestureDetector(
              onTap: () => _showImageLightbox(context, thumbUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  thumbUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.image_outlined,
                      color: EColors.primary.withValues(alpha: 0.6), size: 20),
                ),
              ),
            )
          else
            Icon(file.fileIcon,
                color: EColors.primary.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: ESizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: EColors.textWhite,
                        fontSize: ESizes.fontSizeSm,
                        fontWeight: FontWeight.w500)),
                Text(file.formattedSize,
                    style: TextStyle(
                        color: EColors.textSecondary.withValues(alpha: 0.4),
                        fontSize: ESizes.fontSizeLabel)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.download_outlined,
                color: EColors.primary.withValues(alpha: 0.7), size: 18),
            tooltip: 'Download',
            onPressed: onDownload,
          ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: EColors.textSecondary.withValues(alpha: 0.3),
                  size: 18),
              tooltip: 'Remove',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ESizes.md),
      child: Text(text,
          style: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.35),
              fontSize: ESizes.fontSizeSm)),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESizes.md),
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.md, vertical: ESizes.sm),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border:
            Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: ESizes.sm),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: ESizes.fontSizeSm))),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close,
                color: Colors.redAccent, size: 16),
          ),
        ],
      ),
    );
  }
}
