import '../Models/active_nearby_available.dart';

class GeoFireAssistant {
  static List<ActiveNearByAvailableDrivers> activeNearByAvailableDriversList = [];

  static void deleteOffLineDriverFormList(String driverId) {
    int indexNumber = activeNearByAvailableDriversList.indexWhere((element) => element.driverId == driverId);

    activeNearByAvailableDriversList.removeAt(indexNumber);
  }

  static void updateActiveNearByAvailableDriverLocation(ActiveNearByAvailableDrivers driverWhoMove) {
    int indexNumber = activeNearByAvailableDriversList.indexWhere((element) => element.driverId == driverWhoMove.driverId);

    activeNearByAvailableDriversList[indexNumber].locationLatitude = driverWhoMove.locationLatitude;
    activeNearByAvailableDriversList[indexNumber].locationLongitude = driverWhoMove.locationLongitude;
  }
}