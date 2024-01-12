
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';

import '../Models/directions.dart';
import '../global/Map_key.dart';
import '../infoHandler/app_info.dart';
class PrecisePickupLocation extends StatefulWidget {
  const PrecisePickupLocation({super.key});

  @override
  State<PrecisePickupLocation> createState() => _PrecisePickupLocationState();
}

class _PrecisePickupLocationState extends State<PrecisePickupLocation> {
  LatLng? pickLocation;
  loc.Location location=loc.Location();
  //String? _address;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer<GoogleMapController>();
  GoogleMapController? NewGoogleMapcontroller;

  Position? userCurrentPosition;
  double bottomPaddingOfMap=0;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  GlobalKey<ScaffoldState> scaffoldstate =GlobalKey<ScaffoldState>();
  locateUserPosition () async {
    Position cposition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cposition;

    LatLng latLngPosition = LatLng(
        userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition = CameraPosition(
        target: latLngPosition, zoom: 15);

    NewGoogleMapcontroller!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition));

    //String humanReadableAddress = await AssistantMethods.searchAddressforGeographicCoordinates(userCurrentPosition!, context);
  }
    getAddressFromLatLng() async {
      try {
        GeoData data = await Geocoder2.getDataFromCoordinates(
            latitude: pickLocation!.latitude,
            longitude: pickLocation!.longitude,
            googleMapApiKey: mapKey);
        setState(() {
          Directions userPickUpAddress = Directions();
          userPickUpAddress.locationLatitude = pickLocation!.latitude;
          userPickUpAddress.locationLongitude = pickLocation!.longitude;
          userPickUpAddress.locationName = data.address;

          Provider.of<AppInfo>(context, listen: false)
              .updatePickUpLocationAddress(userPickUpAddress);
          //_address=data.address;
        });
      } catch (e) {
        print(e);

    }
  }
  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(top:100,bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            initialCameraPosition:_kGooglePlex ,
            onMapCreated:
                (GoogleMapController controller){
              _controllerGoogleMap.complete(controller);
              NewGoogleMapcontroller=controller;

              setState(() {
            bottomPaddingOfMap=50;
              });
              locateUserPosition();
            },
             onCameraMove: (CameraPosition? position){
            if(pickLocation != position!.target){
             setState(() {
             pickLocation=position.target;
            });
             }
            },
            onCameraIdle: (){
             getAddressFromLatLng();
            },
          ),
           Align(
          alignment:Alignment.center,
          child: Padding(
          padding:  EdgeInsets.only( top:100,bottom: bottomPaddingOfMap),
          child: Image.asset("images/google-maps.png",height: 45,width: 45,),
           ),
          ),
           Positioned(
              top: 40,
            right: 20,
               left: 20,
              child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
                  color: Colors.black
               ),
                padding: const EdgeInsets.all(20),
                child: Text(Provider.of<AppInfo>(context).userPickUpLocation !=null ?(Provider.of<AppInfo>(context)).userPickUpLocation!.locationName!.substring(0,24) +"......." : "Not Getting Address",

  ),
  ),
 ),
         Positioned( bottom: 0,
           left: 0,
                  right: 0,
              child: Padding(
             padding: const EdgeInsets.all(12),
                child:ElevatedButton(
                     onPressed: (){
                      Navigator.pop(context);
                     },
    style: ElevatedButton.styleFrom(
    backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
    textStyle: const TextStyle(
                     color: Colors.white70,
                   fontWeight:  FontWeight.bold,
                        fontSize: 16,

    ),
    ),

    child: const Text("Set Current Location "),

    ),
    ),
         ),
  ],
    ),
    );
  }
}
