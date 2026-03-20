import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/data/models/portal_file_model.dart';

class PortalFilesRepository {
  final _client = Supabase.instance.client;
  static const _bucket = 'portal-files';

  Future<List<PortalFile>> fetchFiles(String quoteId) async {
    final data = await _client
        .from('portal_files')
        .select()
        .eq('quote_id', quoteId)
        .order('created_at', ascending: false);

    final files = (data as List)
        .map((e) => PortalFile.fromJson(e as Map<String, dynamic>))
        .toList();

    final imageFiles = files.where((f) => f.isImage).toList();
    if (imageFiles.isEmpty) return files;

    final urls = await Future.wait(
      imageFiles.map((f) => createSignedUrl(f.storagePath)),
    );
    final urlMap = {
      for (var i = 0; i < imageFiles.length; i++) imageFiles[i].id: urls[i],
    };

    return files
        .map((f) => urlMap[f.id] != null ? f.withSignedUrl(urlMap[f.id]!) : f)
        .toList();
  }

  Future<int> fetchAdminFileCount(String quoteId) async {
    final data = await _client
        .from('portal_files')
        .select('id')
        .eq('quote_id', quoteId)
        .neq('uploaded_by', 'client')
        .filter('seen_by_client_at', 'is', null);
    return (data as List).length;
  }

  Future<void> markAdminFilesSeenByClient(String quoteId) async {
    await _client
        .from('portal_files')
        .update({'seen_by_client_at': DateTime.now().toUtc().toIso8601String()})
        .eq('quote_id', quoteId)
        .neq('uploaded_by', 'client')
        .filter('seen_by_client_at', 'is', null);
  }

  Future<PortalFile> uploadFile({
    required String quoteId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final storagePath = '$quoteId/client/${ts}_$safeName';

    await _client.storage.from(_bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    final row = await _client.from('portal_files').insert({
      'quote_id': quoteId,
      'uploaded_by': 'client',
      'file_name': fileName,
      'storage_path': storagePath,
      'mime_type': mimeType,
      'size_bytes': bytes.lengthInBytes,
    }).select().single();

    var file = PortalFile.fromJson(row);
    if (file.isImage) {
      final url = await createSignedUrl(file.storagePath);
      file = file.withSignedUrl(url);
    }
    return file;
  }

  Future<String> createSignedUrl(String storagePath) async {
    return _client.storage
        .from(_bucket)
        .createSignedUrl(storagePath, 3600); // 1-hour TTL
  }

  Future<void> deleteFile(String fileId, String storagePath) async {
    await _client.storage.from(_bucket).remove([storagePath]);
    await _client.from('portal_files').delete().eq('id', fileId);
  }
}
