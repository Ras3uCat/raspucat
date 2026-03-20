import 'package:raspucat/app/data/models/portal_file_model.dart';
import 'package:raspucat/app/data/repositories/portal_files_repository.dart';
import 'package:raspucat/app/utils/portal_file_picker.dart';
import 'package:raspucat/utils/constants/exports.dart';
import 'package:url_launcher/url_launcher.dart';

class PortalFilesController extends GetxController {
  final _repo = PortalFilesRepository();
  final String quoteId;

  final files = <PortalFile>[].obs;
  final isLoading = true.obs;
  final isUploading = false.obs;
  final uploadError = RxnString();

  PortalFilesController(this.quoteId);

  List<PortalFile> get clientFiles =>
      files.where((f) => f.isFromClient).toList();
  List<PortalFile> get adminFiles =>
      files.where((f) => !f.isFromClient).toList();

  @override
  void onInit() {
    super.onInit();
    loadFiles();
  }

  Future<void> loadFiles() async {
    isLoading.value = true;
    try {
      files.assignAll(await _repo.fetchFiles(quoteId));
    } finally {
      isLoading.value = false;
    }
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
      final uploaded = await _repo.uploadFile(
        quoteId: quoteId,
        bytes: result.bytes,
        fileName: result.name,
        mimeType: result.mimeType,
      );
      files.insert(0, uploaded);
    } catch (_) {
      uploadError.value = 'Upload failed. Please try again.';
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> downloadFile(PortalFile file) async {
    try {
      final url = await _repo.createSignedUrl(file.storagePath);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      uploadError.value = 'Could not open file. Please try again.';
    }
  }

  Future<void> deleteFile(PortalFile file) async {
    try {
      await _repo.deleteFile(file.id, file.storagePath);
      files.remove(file);
    } catch (_) {
      uploadError.value = 'Could not delete file. Please try again.';
    }
  }
}
