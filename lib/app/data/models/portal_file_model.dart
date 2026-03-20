import 'package:flutter/material.dart';

class PortalFile {
  final String id;
  final String quoteId;
  final String uploadedBy;
  final String fileName;
  final String storagePath;
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;

  final String? signedUrl;

  const PortalFile({
    required this.id,
    required this.quoteId,
    required this.uploadedBy,
    required this.fileName,
    required this.storagePath,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    this.signedUrl,
  });

  PortalFile withSignedUrl(String url) => PortalFile(
        id: id,
        quoteId: quoteId,
        uploadedBy: uploadedBy,
        fileName: fileName,
        storagePath: storagePath,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        createdAt: createdAt,
        signedUrl: url,
      );

  factory PortalFile.fromJson(Map<String, dynamic> json) => PortalFile(
        id: json['id'] as String,
        quoteId: json['quote_id'] as String,
        uploadedBy: json['uploaded_by'] as String,
        fileName: json['file_name'] as String,
        storagePath: json['storage_path'] as String,
        mimeType: json['mime_type'] as String,
        sizeBytes: json['size_bytes'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isFromClient => uploadedBy == 'client';
  bool get isImage => mimeType.startsWith('image/');

  String get formattedSize {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  IconData get fileIcon {
    if (mimeType.startsWith('image/')) return Icons.image_outlined;
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (mimeType == 'application/zip') return Icons.folder_zip_outlined;
    if (mimeType.contains('font') || mimeType.contains('woff')) {
      return Icons.text_fields_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}
