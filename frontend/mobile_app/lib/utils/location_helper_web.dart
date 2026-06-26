// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

Future<({double lat, double lng})?> getCurrentLocation() async {
  try {
    final pos = await html.window.navigator.geolocation.getCurrentPosition();
    return (
      lat: (pos.coords?.latitude ?? 0).toDouble(),
      lng: (pos.coords?.longitude ?? 0).toDouble(),
    );
  } catch (_) {
    return null;
  }
}
