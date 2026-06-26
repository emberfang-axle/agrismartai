import 'dart:typed_data';

/// Image bytes + metadata for the scan pipeline.
class ScanPayload {
  final Uint8List bytes;
  final String? path;
  final DateTime? capturedAt;
  final bool fromCamera;

  const ScanPayload({
    required this.bytes,
    this.path,
    this.capturedAt,
    this.fromCamera = false,
  });
}
