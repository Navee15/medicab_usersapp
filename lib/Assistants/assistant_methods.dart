import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medicab_usersapp/Assistants/request_assistant.dart';
import 'package:medicab_usersapp/Models/directions.dart';
import 'package:medicab_usersapp/Models/trips_history_model.dart';
import 'package:medicab_usersapp/Models/usermodel.dart';
import 'package:medicab_usersapp/global/global.dart';
import 'package:medicab_usersapp/infoHandler/app_info.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;



import '../Models/direction_details_info.dart';
import '../global/Map_key.dart';

class AssistantMethods{
  static void readcurrentOnlineuserInfo() async
  {
    currentUser = fAuth.currentUser;
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(currentUser!.uid);

    userRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
      }
    });
  }

  static Future<String> searchAddressforGeographicCoordinates(Position position,context) async{
    String apiUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = " ";

    var requestResponse = await RequestAssistant.recieveRequest(apiUrl);

    if(requestResponse != "Error occurred,Failed. No Response.") {
     humanReadableAddress = requestResponse["results"][0]["formatted_address"];

      Directions userPickupAddress =Directions();
      userPickupAddress.locationLatitude=position.latitude;
      userPickupAddress.locationLongitude=position.longitude;
      userPickupAddress.locationName = humanReadableAddress;

      Provider.of<AppInfo>(context,listen:false).updatePickUpLocationAddress(userPickupAddress);
    }
    return humanReadableAddress;
  }
  static Future<DirectionDetailsInfo> obtainOriginToDestinationDirection(LatLng originPosition,LatLng destinationPosition) async {
    String urlOriginToDestinationDirectionDetails = "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";
    var responseDirectionApi = await RequestAssistant.recieveRequest(urlOriginToDestinationDirectionDetails);

    // if(responseDirectionApi == "Error Occurred. Failed. No Response"){
    //  return null;
   // }
    DirectionDetailsInfo directionDetailsInfo=DirectionDetailsInfo();
    directionDetailsInfo.e_point=responseDirectionApi["routes"][0]["overview_polyline"]["points"];

    directionDetailsInfo.distance_text=responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
    directionDetailsInfo.distance_value=responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];

    directionDetailsInfo.duration_text=responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
    directionDetailsInfo.duration_value=responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetailsInfo;

  }
static double calculateFareAmountFromOriginToDestination(DirectionDetailsInfo directionDetailsInfo){
    double timeTravelledFairAmountPerMinute = (directionDetailsInfo.duration_value! /60)*0.1;
    double distanceTravelledFareAmountPerKilometer = (directionDetailsInfo.duration_value! /1000) *0.1;
    double totalFareAmount =timeTravelledFairAmountPerMinute + distanceTravelledFareAmountPerKilometer;
    return double.parse(totalFareAmount.toStringAsFixed(1));
}
  static sendNotificationToDriverNow(String deviceRegistrationToken, String userRideRequestId, context) async {
    String destinationAddress = userDropOffAddress;

    Map<String, String> headerNotification = {
      'Content-Type': 'application/json',
      'Authorization': cloudMessagingServerToken,
    };

    Map bodyNotification = {
      "body":"Destination Address: \n$destinationAddress.",
      "title":"New Trip Request"
    };

    Map dataMap = {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done",
      "rideRequestId": userRideRequestId
    };

    Map officialNotificationFormat = {
      "notification": bodyNotification,
      "data": dataMap,
      "priority": "high",
      "to": deviceRegistrationToken,
    };

    var responseNotification = http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: headerNotification,
      body: jsonEncode(officialNotificationFormat),
    );
  }

//retrieve the trips keys for online user
static void readTripKeysForOnlineUser(context){
    FirebaseDatabase.instance.ref().child("All Ride Requests").orderByChild("userName").equalTo(userModelCurrentInfo!.name).once().then((snap){
      if(snap.snapshot.value!= null){
        Map keysTripsId=snap.snapshot.value as Map;
        //total trips count
        int overAllTripsCounter =keysTripsId.length;
        Provider.of<AppInfo>(context,listen: false).updateOverAllTripCounter(overAllTripsCounter);
      //share trips keys with provider
        List<String>tripKeysList =[];
        keysTripsId.forEach((key, value) {
          tripKeysList.add(key);
        });
        Provider.of<AppInfo>(context,listen: false).updateOverAllTripKeys(tripKeysList);
        //get trips keys data =read trips complete information
        readTripsHistoryInformation(context);
      }
    }
    );
}
static void readTripsHistoryInformation(context){
    var tripsAllKeys=Provider.of<AppInfo>(context,listen: false).historyTripsKeysList;
   for( String eachKey in tripsAllKeys){
     FirebaseDatabase.instance.ref()
         .child("All Ride Requests")
         .child(eachKey)
         .once()
         .then((snap){
           var eachTripHistory = TripsHistoryModel.fromSnapshot(snap.snapshot);

           if((snap.snapshot.value as Map)["status"]=="ended"){
             //update or add each history to OverAllTrips History data list
           Provider.of<AppInfo>(context,listen: false).updateOverAllTripsHistoryInformation(eachTripHistory);
           }
     });
   }
  }
}
