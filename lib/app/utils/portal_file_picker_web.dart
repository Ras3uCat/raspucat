// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';

typedef PortalFileResult = ({
  String name,
  String mimeType,
  Uint8List bytes,
});

const _maxBytes = 50 * 1024 * 1024; // 50 MB

const _acceptedExtensions =
    '.jpg,.jpeg,.png,.svg,.webp,.pdf,.zip,.ttf,.otf,.woff,.woff2';

/// Opens a native file picker and returns the selected file's bytes.
/// Returns null if the user cancels. Throws a [PortalFilePickerException]
/// if the file exceeds the size limit.
Future<PortalFileResult?> pickPortalFile() async {
  final completer = Completer<PortalFileResult?>();
  final input = html.FileUploadInputElement()
    ..accept = _acceptedExtensions
    ..style.display = 'none';

  html.document.body!.append(input);

  var fileSelected = false;

  input.onChange.listen((_) async {
    fileSelected = true;
    input.remove();
    if (input.files == null || input.files!.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = input.files!.first;

    if (file.size > _maxBytes) {
      completer.completeError(
        const PortalFilePickerException('File exceeds the 50 MB limit.'),
      );
      return;
    }

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final result = reader.result;
    final bytes = result is ByteBuffer
        ? Uint8List.view(result)
        : result as Uint8List;

    final mimeType = file.type.isNotEmpty
        ? file.type
        : _mimeFromExtension(file.name);

    completer.complete((name: file.name, mimeType: mimeType, bytes: bytes));
  });

  // Detect picker dismissal without selection via window regaining focus
  html.window.onFocus.first.then((_) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!fileSelected && !completer.isCompleted) {
        input.remove();
        completer.complete(null);
      }
    });
  });

  input.click();
  return completer.future;
}

String _mimeFromExtension(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'svg' => 'image/svg+xml',
    'webp' => 'image/webp',
    'pdf' => 'application/pdf',
    'zip' => 'application/zip',
    'ttf' => 'font/ttf',
    'otf' => 'font/otf',
    'woff' => 'font/woff',
    'woff2' => 'font/woff2',
    _ => 'application/octet-stream',
  };
}

class PortalFilePickerException implements Exception {
  const PortalFilePickerException(this.message);
  final String message;

  @override
  String toString() => message;
}
