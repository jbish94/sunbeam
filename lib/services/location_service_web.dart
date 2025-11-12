import 'dart:html' as html;

class LocationService {
  Future<void> init() async {}
  Future<String> getLocation() async {
    final nav = html.window.navigator.geolocation;
    if (nav != null) {
      final position = await nav.getCurrentPosition();
      final coords = position.coords;
      return '${coords?.latitude}, ${coords?.longitude}';
    }
    return 'Unavailable';
  }
}
