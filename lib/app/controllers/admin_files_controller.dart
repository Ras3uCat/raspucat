import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/utils/portal_file_picker.dart';
import 'package:raspucat/app/data/models/portal_file_model.dart';

/// PortalFile with a short-lived signed URL attached (admin-side only).
class AdminFile {
  final PortalFile file;
  final String? signedUrl;

  const AdminFile({required this.file, this.signedUrl});

  factory AdminFile.fromJson(Map<String, dynamic> json) => AdminFile(
        file: PortalFile.fromJson(json),
        signedUrl: json['signed_url'] as String?,
      );
}

class AdminFilesController extends GetxController {
  final String quoteId;
  AdminFilesController(this.quoteId);

  final files = <AdminFile>[].obs;
  final isLoading = true.obs;
  final isUploading = false.obs;
  final uploadError = RxnString();
  final newClientFileCount = 0.obs;
  final ScrollController scrollController = ScrollController();
  bool _clientFilesViewed = false;

  RealtimeChannel? _realtimeChannel;

  String get _token => AdminController.instance.adminToken;

  List<AdminFile> get clientFiles =>
      files.where((f) => f.file.isFromClient).toList();
  List<AdminFile> get adminFiles =>
      files.where((f) => !f.file.isFromClient).toList();

  @override
  void onInit() {
    super.onInit();
    loadFiles();
    _subscribeRealtime();
  }

  @override
  void onClose() {
    _realtimeChannel?.unsubscribe();
    scrollController.dispose();
    super.onClose();
  }

  void _subscribeRealtime() {
    _realtimeChannel = Supabase.instance.client
        .channel('admin_files_$quoteId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'portal_files',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'quote_id',
            value: quoteId,
          ),
          callback: (_) => loadFiles(),
        )
        .subscribe();
  }

  Future<void> loadFiles() async {
    isLoading.value = true;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-get-files',
        body: {'adminToken': _token, 'quoteId': quoteId},
      );
      final data = response.data as Map<String, dynamic>?;
      final list = (data?['files'] as List<dynamic>? ?? [])
          .map((e) => AdminFile.fromJson(e as Map<String, dynamic>))
          .toList();
      files.assignAll(list);
      if (!_clientFilesViewed) {
        newClientFileCount.value = clientFiles.length;
      }
    } catch (_) {
      // Leave files unchanged on error
    } finally {
      isLoading.value = false;
    }
  }

  void markClientFilesViewed() {
    _clientFilesViewed = true;
    newClientFileCount.value = 0;
  }

  Future<void> pickAndUpload() async {
    uploadError.value = null;
    PortalFileResult? result;
    try {
      result = await pickPortalFile();
    } catch (e) {
      uploadError.value = e.toString();
      return;
    }
    if (result == null) return;

    isUploading.value = true;
    try {
      final base64 = base64Encode(result.bytes);
      final response = await Supabase.instance.client.functions.invoke(
        'admin-upload-file',
        body: {
          'adminToken': _token,
          'quoteId': quoteId,
          'fileName': result.name,
          'mimeType': result.mimeType,
          'fileBase64': base64,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        uploadError.value = data!['error'] as String;
      } else if (data?['file'] != null) {
        final newFile =
            AdminFile.fromJson(data!['file'] as Map<String, dynamic>);
        files.insert(0, newFile);
      }
    } catch (_) {
      uploadError.value = 'Upload failed. Please try again.';
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> downloadFile(AdminFile f) async {
    final url = f.signedUrl;
    if (url == null || url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      uploadError.value = 'Could not open file.';
    }
  }

  Future<void> deleteFile(AdminFile f) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'admin-delete-file',
        body: {
          'adminToken': _token,
          'fileId': f.file.id,
          'storagePath': f.file.storagePath,
        },
      );
      files.remove(f);
    } catch (_) {
      uploadError.value = 'Could not delete file. Please try again.';
    }
  }
}
