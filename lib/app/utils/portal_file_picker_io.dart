import 'dart:typed_data';

typedef PortalFileResult = ({
  String name,
  String mimeType,
  Uint8List bytes,
});

/// Non-web stub — file picking is only supported on web for the portal.
Future<PortalFileResult?> pickPortalFile() async => null;
