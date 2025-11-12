export 'location_service_stub.dart'
    if (dart.library.html) 'location_service_web.dart'
    if (dart.library.io) 'location_service_mobile.dart';

import 'services/location_service.dart';

final location = LocationService();

await location.init();
final coords = await location.getLocation();
print(coords);
