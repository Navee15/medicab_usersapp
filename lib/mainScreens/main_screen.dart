import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medicab_usersapp/Assistants/assistant_methods.dart';
import 'package:medicab_usersapp/Assistants/black_theme_google_map.dart';
import 'package:medicab_usersapp/Assistants/geofire_assistant.dart';
import 'package:medicab_usersapp/Authentication/search_places_screen.dart';
import 'package:medicab_usersapp/Models/active_nearby_available.dart';
import 'package:medicab_usersapp/mainScreens/precise_pickup_location.dart';
import 'package:medicab_usersapp/mainScreens/rate_driver_screen.dart';
import 'package:medicab_usersapp/splashScreen/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../global/global.dart';
import '../infoHandler/app_info.dart';
import '../widgets/pay_fare_amount_dialog.dart';
import '../widgets/progress_dialog.dart';
import 'drawer_screen.dart';

Future<void> _makePhoneCall(String url) async {
  if(await canLaunch(url)) {
    await launch(url);
  }
  else{
    throw "Could not launch $url";
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});


  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  LatLng? pickLocation;
  loc.Location location=loc.Location();
  //String? _address;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer<GoogleMapController>();

  GoogleMapController?  NewGoogleMapcontroller;
  static final CameraPosition _kGooglePlex = const CameraPosition(target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746);
  GlobalKey<ScaffoldState>scaffoldstate=GlobalKey<ScaffoldState>();

  double searchLocationContainerHeight=220;
  double waitingResponsefromDriverContainerHeight=0;
  double assignedDriverInfoContainerHeight=0;
  double suggestedRidesContainerHeight = 0;
  Position? userCurrentPosition;
  var geoLocator=Geolocator();
  LocationPermission? _locationPermission;
  double bottomPaddingOfMap=0;
  List<LatLng> PLineCoOrdinatesList =[];
  Set<Polyline> polylineSet ={};
  Set<Marker> MarkerSet ={};
  Set<Circle> CircleSet ={};
  String userName ="";
  String userEmail="";
  bool openNavigationDrawer =true;
  bool activeNearbyDriverKeysLoaded =false;
  BitmapDescriptor? activeNearbyIcon;
  bool requestPositionInfo =true;
  DatabaseReference? referenceRideRequest;
  String selectedVehicleType="";
  String driverRideStatus ="Driver is coming";
  String userRideRequestStatus="";
  StreamSubscription<DatabaseEvent>?tripRidesRequestInfoStreamSubscription;
  List<ActiveNearByAvailableDrivers> onlineNearByAvailableDriversList =[];
  double searchingForDriverContainerHeight = 0;



  locateUserPosition () async {
    Position cposition=await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition=cposition;

    LatLng latLngPosition=LatLng(userCurrentPosition!.latitude,userCurrentPosition!.longitude);
    CameraPosition cameraPosition=CameraPosition(target: latLngPosition,zoom: 15);

    NewGoogleMapcontroller!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

     String humanReadableAddress = await AssistantMethods.searchAddressforGeographicCoordinates(userCurrentPosition!, context) ;
     print("This is our Address =$humanReadableAddress");
    userName = userModelCurrentInfo!.name!;
    userEmail = userModelCurrentInfo!.email!;

    initializeGeoFireListener();
    AssistantMethods.readTripKeysForOnlineUser(context);

  }

  initializeGeoFireListener() {
    Geofire.initialize("activeDrivers");

    Geofire.queryAtLocation(userCurrentPosition!.latitude, userCurrentPosition!.longitude, 10)!
      .listen((map) {
        print(map);

        if(map != null) {
          var callBack =map["callBack"];

          switch(callBack) {
            //whenever any driver become active/online
            case Geofire.onKeyEntered:
              ActiveNearByAvailableDrivers activeNearByAvailableDrivers = ActiveNearByAvailableDrivers();
              activeNearByAvailableDrivers.locationLatitude = map["latitude"];
              activeNearByAvailableDrivers.locationLongitude = map["longitude"];
              activeNearByAvailableDrivers.driverId = map["key"];
              GeoFireAssistant.activeNearByAvailableDriversList.add(activeNearByAvailableDrivers);
              if(activeNearbyDriverKeysLoaded == true) {
                displayActiveDriversOnUsersMap();
              }
              break;
            //whenever any driver become non-active/online
            case Geofire.onKeyExited:
              GeoFireAssistant.deleteOffLineDriverFormList(map["key"]);
              displayActiveDriversOnUsersMap();
              break;
            //whenever driver moves - update driver location
            case Geofire.onKeyMoved:
              GeoFireAssistant.activeNearByAvailableDriversList.clear();
              ActiveNearByAvailableDrivers activeNearByAvailableDrivers = ActiveNearByAvailableDrivers();
              activeNearByAvailableDrivers.locationLatitude = map["latitude"];
              activeNearByAvailableDrivers.locationLongitude = map["longitude"];
              activeNearByAvailableDrivers.driverId = map["key"];
              GeoFireAssistant.updateActiveNearByAvailableDriverLocation(activeNearByAvailableDrivers);
              displayActiveDriversOnUsersMap();
              break;

              //display those online active drivers on user's app
            case Geofire.onGeoQueryReady:
              activeNearbyDriverKeysLoaded = true;
              displayActiveDriversOnUsersMap();
              break;
          }
        }
        setState(() {

        });
      }
    );
  }

  displayActiveDriversOnUsersMap() {
    setState(() {
      MarkerSet.clear();
      CircleSet.clear();

      Set<Marker> driverMarkerSet = Set<Marker>();

      for(ActiveNearByAvailableDrivers eachDriver in GeoFireAssistant.activeNearByAvailableDriversList) {
        LatLng eachDriverActivePosition = LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);

        Marker marker = Marker(
          markerId: MarkerId(eachDriver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );

        driverMarkerSet.add(marker);
      }

        setState(() {
          MarkerSet = driverMarkerSet;
        });
      
    });
  }
  
  createActiveNearByDriverIconMarker(){
    if(activeNearbyIcon == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: const Size(0.02, 0.02));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/ambu.jpeg").then((value){
        activeNearbyIcon = value;
      });
    }
  }

  Future<void>drawPolyLineFromOriginToDestination(bool darkTheme) async {
    var originPosition = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;

    var destinationPosition = Provider.of<AppInfo>(context,listen: false).userDropOffLocation;

    var originLatLng = LatLng(originPosition!.locationLatitude!,originPosition.locationLongitude!);

    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!,destinationPosition.locationLongitude!);

    showDialog(
      context: context,
      builder: (BuildContext context) =>
          ProgressDialog(message: "Please Wait....",),
    );
    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirection(originLatLng, destinationLatLng);
    setState(() {
      tripDirectionDetailsInfo = directionDetailsInfo;
    });
    Navigator.pop(context);
    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodePolylinePointsResultList = pPoints.decodePolyline(directionDetailsInfo.e_point!);

    PLineCoOrdinatesList.clear();
    if(decodePolylinePointsResultList.isNotEmpty){
      decodePolylinePointsResultList.forEach((PointLatLng pointLatLng){
        PLineCoOrdinatesList.add(LatLng(pointLatLng.latitude,pointLatLng.longitude));
      });
    }
    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: darkTheme ? Colors.amberAccent : Colors.blue,
        polylineId: const PolylineId("PolyLineId"),
        jointType: JointType.round,
        points: PLineCoOrdinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 5,
      );

      polylineSet.add(polyline);
    });
    LatLngBounds boundsLatLng;
    if(originLatLng.latitude > destinationLatLng.latitude && originLatLng.longitude > destinationLatLng.longitude){
      boundsLatLng= LatLngBounds(southwest: destinationLatLng,northeast: originLatLng);
    }
    else if(originLatLng.longitude >destinationLatLng.longitude){
      boundsLatLng=LatLngBounds(
        southwest: LatLng(originLatLng.latitude,destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    }
    else if(originLatLng.latitude > destinationLatLng.latitude){
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude,originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),

      );
    }
    else{
      boundsLatLng = LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }
    NewGoogleMapcontroller!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMaker = Marker(
      markerId: const MarkerId("originId"),
      infoWindow: InfoWindow(title: originPosition.locationName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );
    Marker destinationMaker = Marker(
    markerId: const MarkerId("destinationId"),
    infoWindow: InfoWindow(title: destinationPosition.locationName, snippet: "Destination"),
    position: destinationLatLng,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
    MarkerSet.add(originMaker);
    MarkerSet.add(destinationMaker);
    });
    Circle originCircle = Circle(
      circleId: const CircleId("originId"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    ); //Circle

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationId"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    ); //Circle

    setState(() {
      CircleSet.add(originCircle);
      CircleSet.add(destinationCircle);
    });
  }
  void showSearchingForDriverContainer() {
    setState(() {
      searchingForDriverContainerHeight = 200;
    });
  }

  void showSuggestedRidesContainer(){
    setState(() {
      suggestedRidesContainerHeight = 400;
      bottomPaddingOfMap = 400;
    });
  }

  checkIfLocationPermissionsAllowed() async{
    _locationPermission =await Geolocator.requestPermission();
    if(_locationPermission==LocationPermission.denied){
      _locationPermission=await Geolocator.requestPermission();
    }
  }



  @override
  void initState(){
    super.initState();

    checkIfLocationPermissionsAllowed();
  }
  saveRideRequestInformation( String selectedVehicleType){
  //save tge ride request information
    referenceRideRequest=FirebaseDatabase.instance.ref().child("All Ride Requests").push();
    var originLocation =Provider.of<AppInfo>(context,listen: false).userPickUpLocation;
    var destinationLocation =Provider.of<AppInfo>(context,listen: false).userDropOffLocation;

    Map originLocationMap = {
      //key:value
      "latitude":originLocation!.locationLatitude.toString(),
      "longitude":originLocation.locationLongitude.toString(),
    };
    Map destinationLocationMap = {
      //key:value
      "latitude":destinationLocation!.locationLatitude.toString(),
      "longitude":destinationLocation.locationLongitude.toString(),
    };
    Map userInformationMap ={
      "origin":originLocationMap,
      "destination":destinationLocationMap,
      "time":DateTime.now().toString(),
      "userName":userModelCurrentInfo!.name,
      "userPhone":userModelCurrentInfo!.phone,
      "originAddress":originLocation.locationName,
      "destinationAddress":destinationLocation.locationName,
      "driverId":"waiting",
    };
    referenceRideRequest!.set(userInformationMap);
    tripRidesRequestInfoStreamSubscription=referenceRideRequest!.onValue.listen((eventSnap)async {
      if(eventSnap.snapshot.value==null){
        return;
      }
      if((eventSnap.snapshot.value as Map)["Ambulance_Details"] != null){
        setState(() {
          driverAmbulanceDetails=(eventSnap.snapshot.value as Map)["Ambulance_Details"].toString();
        });
      }
      if((eventSnap.snapshot.value as Map)["driverPhone"] != null){
        setState(() {
          driverPhone=(eventSnap.snapshot.value as Map)["driverPhone"].toString();
        });
      }
      if((eventSnap.snapshot.value as Map)["driverName"] != null){
        setState(() {
          driverName=(eventSnap.snapshot.value as Map)["driverName"].toString();
        });
      }
      if((eventSnap.snapshot.value as Map)["ratings"] != null){
        setState(() {
          driverRatings=(eventSnap.snapshot.value as Map)["ratings"].toString();
        });
      }
      if((eventSnap.snapshot.value as Map)["status"] != null){
        setState(() {
          userRideRequestStatus=(eventSnap.snapshot.value as Map)["status"].toString();
        });
      }
      if((eventSnap.snapshot.value as Map)["driverLocation"] !=null){
        double driverCurrentPositionLat=double.parse((eventSnap.snapshot.value as Map)["driverLocation"]["latitude"].toString());
        double driverCurrentPositionLng=double.parse((eventSnap.snapshot.value as Map)["driverLocation"]["longitude"].toString());
         LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPositionLat, driverCurrentPositionLng);
         //status=accepted
        if(userRideRequestStatus=="accepted"){
          updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng);
          setState(() {
            assignedDriverInfoContainerHeight=250;
            searchingForDriverContainerHeight =0;
            suggestedRidesContainerHeight = 0;

          });
        }
        //status=arrived
        if(userRideRequestStatus=="arrived"){
          setState(() {
            driverRideStatus="Driver has arrived";
          });
        }
        //status =onTrip
        if(userRideRequestStatus=="onTrip"){
          updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
        }
        if(userRideRequestStatus=="ended"){
          if((eventSnap.snapshot.value as Map)["fareAmount"] != null){
            double fareAmount =double.parse((eventSnap.snapshot.value as Map)["fareAmount"].toString());

         var response =await showDialog(
             context: context,
             builder:(BuildContext context)=> payFareAmountDialog(
               fareAmount:fareAmount,
         )
      );
         if(response=="cash paid"){
           //user can rate the driver
           if((eventSnap.snapshot.value as Map)["driverId"] != null){
             String assignedDriverId=(eventSnap.snapshot.value as Map)["driverId"].toString();
            Navigator.push(context, MaterialPageRoute( builder:(c)=> RateDriverScreen(assignDriverId: assignedDriverId)));
          referenceRideRequest!.onDisconnect();
          tripRidesRequestInfoStreamSubscription!.cancel();
           }
         }
          }
        }
      }
    });
onlineNearByAvailableDriversList = GeoFireAssistant.activeNearByAvailableDriversList;
searchNearestOnlineDrivers(selectedVehicleType);
  }
  searchNearestOnlineDrivers(String selectedVehicleType) async {
    if(onlineNearByAvailableDriversList.isEmpty) {
      //Cancel?delete the ride-request information
      referenceRideRequest!.remove();

      setState(() {
        polylineSet.clear();
        MarkerSet.clear();
        CircleSet.clear();
        PLineCoOrdinatesList.clear();
      });

      Fluttertoast.showToast(msg: "No Online nearest Driver Available");
      Fluttertoast.showToast(msg: "Search Again. \n Restarting App");

      Future.delayed(const Duration(milliseconds: 4000), () {
        referenceRideRequest!.remove();
        Navigator.push(context, MaterialPageRoute(builder: (c) => const MySplashScreen()));
      });

      return;
    }

    await retrieveOnlineDriversInformation(onlineNearByAvailableDriversList);

    print("driver List: " + driversList.toString());

    for(int i=0;i<driversList.length;i++){
      if(driversList[i]["Ambulance_Details"]["type"] == selectedVehicleType){
        AssistantMethods.sendNotificationToDriverNow(driversList[i]["token"], referenceRideRequest!.key!, context);
      }
    }

    Fluttertoast.showToast(msg: "Notification sent Successfully");

    showSearchingForDriverContainer();

    FirebaseDatabase.instance.ref().child("All Ride requests").child(referenceRideRequest!.key!).child("driverId").onValue.listen((eventRideRequestSnapshot) {
      print("EventSnapshot: ${eventRideRequestSnapshot.snapshot.value}");
      if(eventRideRequestSnapshot.snapshot.value != null){
        if(eventRideRequestSnapshot.snapshot.value != "waiting"){
          showUIForAssignedDriverInfo();
        }
      }
    });

  }

  updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng) async {
    if(requestPositionInfo == true){
      requestPositionInfo = false;
      LatLng userPickUpPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirection(
        driverCurrentPositionLatLng, userPickUpPosition,
      );

      if(directionDetailsInfo == null){
        return;
      }
      setState(() {
        driverRideStatus = "Driver is coming: ${directionDetailsInfo.duration_text.toString()}";
      });

      requestPositionInfo = true;
    }
  }
  updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng) async {
    if(requestPositionInfo == true){
      requestPositionInfo = false;

      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

      LatLng userDestinationPosition = LatLng(
        dropOffLocation!.locationLatitude!,
        dropOffLocation.locationLongitude!,
      );

      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirection(
          driverCurrentPositionLatLng,
          userDestinationPosition
      );

      if(directionDetailsInfo == null){
        return;
      }
      setState(() {
        driverRideStatus = "Going Towards Destination: ${directionDetailsInfo.duration_text.toString()}";
      });

      requestPositionInfo = true;
    }
  }

  showUIForAssignedDriverInfo() {
    setState(() {
      waitingResponsefromDriverContainerHeight =0;
      searchLocationContainerHeight = 0;
      assignedDriverInfoContainerHeight = 200;
      suggestedRidesContainerHeight = 0;
      bottomPaddingOfMap = 200;
    });
  }

  retrieveOnlineDriversInformation(List onlineNearestDriversList) async {
    driversList.clear();
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");

    for(int i=0;i<onlineNearestDriversList.length;i++){
      await ref.child(onlineNearByAvailableDriversList[i].driverId.toString()).once().then((dataSnapshot) {
        var driverKeyInfo = dataSnapshot.snapshot.value;

        driversList.add(driverKeyInfo);
        print("driver key information = " + driversList.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    createActiveNearByDriverIconMarker();

    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },

      child:Scaffold(
        key:  scaffoldstate,
      drawer:const DrawerScreen(),
      body: Stack(
      children: [
      GoogleMap(
      mapType: MapType.normal,
      myLocationEnabled: true,
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      initialCameraPosition:_kGooglePlex ,
      polylines: polylineSet,
      markers: MarkerSet,
      circles: CircleSet,
      onMapCreated:
          (GoogleMapController controller){
        _controllerGoogleMap.complete(controller);
        NewGoogleMapcontroller=controller;
        if(darkTheme==true){
          setState(() {
            blackThemeGoogleMap(NewGoogleMapcontroller);
          });
        }

        setState(() {

        });
        locateUserPosition();
      },

    ),

    //ui for searching
         //custom hamburger button
        Positioned(
          top: 50,
          left: 20,
          child: GestureDetector(
            onTap: (){
              scaffoldstate.currentState!.openDrawer();
            },
            child: CircleAvatar(
              backgroundColor:darkTheme? Colors.amber.shade400 : Colors.white ,
              child: Icon(
                Icons.menu,
                color: darkTheme? Colors.black: Colors.lightBlue,
              ),
            ),
          ),
        ),
               Positioned(
                 bottom: 0,
                  left: 0,
                   right: 0,
                   child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 50, 10, 10),
                         child: Column(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
    Container(
    padding:const EdgeInsets.all(10),
    decoration: BoxDecoration(
    color:   Colors.white,
    borderRadius: BorderRadius.circular(10)
    ),
    child: Column(
    children: [
    Container(
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10)
    ),
    child: Column(
    children: [
    Padding(
    padding:const EdgeInsets.all(5),
    child: Row(
    children: [
    const Icon(Icons.location_on_outlined, color: Colors.blue ),
    const SizedBox(width: 10,),
    Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text("From",
    style:  TextStyle(
    color:  Colors.blue ,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    ),
    ),
    Text(Provider.of<AppInfo>(context).userPickUpLocation !=null ?(Provider.of<AppInfo>(context)).userPickUpLocation!.locationName!.substring(0,24) +"......." : "Not getting address",
    style: const TextStyle(color: Colors.grey, fontSize: 14),
    )
    ],
    )
    ],
    ),
    ),


    const SizedBox(height: 5,),

    const Divider(
    height: 1,
    thickness: 2,
    color:  Colors.blue ,
    ),

    const SizedBox(height: 5,),

    Padding(
    padding:const EdgeInsets.all(5),
    child: GestureDetector(
    onTap: () async {
      //go to  search places screen
      var repsonseFromSearchScreen = await Navigator.push(context, MaterialPageRoute(builder: (c) =>const SearchPlacesScreen()));

      if (repsonseFromSearchScreen == "obtainedDropoff") {
        setState(() {
          openNavigationDrawer = false;
        });
      }
      await drawPolyLineFromOriginToDestination(darkTheme);
    },
    child: Row(
    children: [
    const Icon(Icons.location_on_outlined, color:  Colors.blue ),
    const SizedBox(width: 10,),
    Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text("To",
    style: TextStyle(
    color:  Colors.blue ,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    ),
    ),
    Text(Provider.of<AppInfo>(context).userDropOffLocation != null
        ? Provider.of<AppInfo>(context).userDropOffLocation!.locationName!: "Where To",
    style: const TextStyle(color: Colors.grey, fontSize: 14),
    )
    ],
    )
    ],
    ),

    ),
    )
    ],
    ),
    ),
      const SizedBox(height:4,),
          Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                  children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder:
                  (c) => const PrecisePickupLocation()));
                },
              child:Text("Change Pick Up Address",
                  style: TextStyle(
                    color: darkTheme ? Colors.black: Colors.white,
                  ),),
              style: ElevatedButton.styleFrom(
                  backgroundColor: darkTheme ? Colors.amber.shade400 :
                  Colors.blue,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14),),
          ),
          const SizedBox(height: 5,),

          ElevatedButton(
              onPressed: () {
                if(Provider.of<AppInfo>(context,listen: false).userDropOffLocation != null){
                  showSuggestedRidesContainer();
                }
                else{
                  Fluttertoast.showToast(msg: "Please select destination location");
                }
              },
              child: Text("Show Fare",
                  style: TextStyle(
                    color: darkTheme ? Colors.black: Colors.white,
                  )
              ),
              style: ElevatedButton.styleFrom(
                  backgroundColor: darkTheme ? Colors.amber.shade400 :
                  Colors.blue,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12
                  )
              )
          )



        ],
            ),
        ],
          ),
             )
             ],

             ),
          )

    ),
        //ui for suggested places
        Positioned(
          left:0,
          right:0,
          bottom:0,
          child:Container(
            height: suggestedRidesContainerHeight,
            decoration: BoxDecoration(
              color: darkTheme? Colors.black :Colors.white,
              borderRadius: const BorderRadius.only(
              topRight:Radius.circular(20),
                topLeft: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: darkTheme? Colors.amber.shade400:Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width:15,),
                      Text(Provider.of<AppInfo>(context).userPickUpLocation !=null ?"${(Provider.of<AppInfo>(context)).userPickUpLocation!.locationName!.substring(0,24)}......." : "Not getting address",
                        style: const TextStyle(
                            color:Colors.black,fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20,),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color:Colors.grey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width:15,),
                      Text(Provider.of<AppInfo>(context).userDropOffLocation != null
                          ? Provider.of<AppInfo>(context).userDropOffLocation!.locationName!: "Where To",                        style: const TextStyle(
                            color:Colors.black,fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20,),

                  const Text("Suggested Rides",
                  style:TextStyle(
                    color: Colors.black,
                    fontWeight:FontWeight.bold,
                  ),
                  ),
                  const SizedBox(height: 20,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: (){
                          setState(() {
                               selectedVehicleType="Ambulance";
                          });
                       },
                        child: Container(
                        decoration: BoxDecoration(
                          color: selectedVehicleType=="Ambulance" ? (darkTheme ? Colors.amber.shade400 : Colors.blue) :(darkTheme ? Colors.black54 : Colors.grey[100]) ,
                        borderRadius: BorderRadius.circular(12),

                                                 ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Column(
                              children: [
                                Image.asset("images/2389124.webp", scale: 2,),
                                 Text("Ambulance",
                                  style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedVehicleType =="Ambulance"? (darkTheme ? Colors.black : Colors.white):(darkTheme ? Colors.white : Colors.black),
                                ),
                                ),
                                const SizedBox(height:2,),
                                  Text(tripDirectionDetailsInfo != null ? " ₹ ${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) *2)*20).toStringAsFixed(1)}"
                                 :"null",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  ),
                        
                              ],
                            ),
                          ),
                                            ),
                      ),
                      GestureDetector(
                        onTap: (){
                          setState(() {
                            selectedVehicleType="Bike";
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: selectedVehicleType=="Bike" ? (darkTheme ? Colors.amber.shade400 : Colors.blue) :(darkTheme ? Colors.black54 : Colors.grey[100]) ,
                            borderRadius: BorderRadius.circular(12),

                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Column(
                              children: [
                                Image.asset("images/biker.png", scale: 2,),
                                Text("Bike",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selectedVehicleType =="Bike"? (darkTheme ? Colors.black : Colors.white):(darkTheme ? Colors.white : Colors.black),
                                  ),
                                ),
                                const SizedBox(height:2,),
                                Text(tripDirectionDetailsInfo != null ? " ₹ ${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) *1.5)*20).toStringAsFixed(1)}"
                                    :"null",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                 const SizedBox(height: 20,),
                  Expanded(
                      child: GestureDetector(
                        onTap: (){
                              if(selectedVehicleType != " "){
                                saveRideRequestInformation(selectedVehicleType);
                              }
                              else{
                                Fluttertoast.showToast(msg: "please select a vehicle from \n suggested rides ");
                              }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                          color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                          borderRadius:BorderRadius.circular(10)
                        ),
                          child:  Center(

                            child: Text(
                              "Request a Raid",
                              style:TextStyle(
                                color: darkTheme ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      )
                  ),
                ],
              ),
            ),
          ),
        ),
        //Requesting a raid
                  Positioned(
                    bottom: 0,
                      left: 0,
                    right: 0,
                       child: Container(
                        height: searchingForDriverContainerHeight,
                         decoration: BoxDecoration(
                            color: darkTheme ? Colors.black : Colors.white,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(15),topRight: Radius.circular(15)),
                         ),
                        child: Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            child: Column(
                           crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                               children:[
                                LinearProgressIndicator(
                                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                ),

                                  const SizedBox(height: 10,),

                                        const Center(
                                         child: Text(
                                           "Searching for a driver...",
                                             style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 22,
                                               fontWeight: FontWeight.bold,
                                                   ),
                                               ),
                                             ),
                                 const SizedBox(height:20,),

                                     GestureDetector(
                                     onTap: (){
                                     referenceRideRequest!.remove();

                                      setState(() {
                                      searchingForDriverContainerHeight =0;
                                      suggestedRidesContainerHeight = 0;
                                      });
                                        },
                                        child: Container(
                                            height:50,
                                              width:50,
                                       decoration: BoxDecoration(
                                            color: darkTheme ? Colors.black :Colors.white,
                                             borderRadius: BorderRadius.circular(25),
                                                border: Border.all(width:1,color: Colors.grey),
                                          ),
                                           child: const Icon(Icons.close,size:25, color: Colors.black,),
                ),
            ),

                const SizedBox(height:15,),

                const SizedBox(
                  width:double.infinity,
                  child: Text(
                    "Cancel",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize:12, fontWeight: FontWeight.bold),
                  ),
                ),
                ],

              ),
            ),

          ),
        ),

            //UI for displaying assigned driver information
            Positioned(
                   bottom: 0,
                     left: 0,
                  right: 0,
                       child: Container(
                  height: assignedDriverInfoContainerHeight,
                  decoration: BoxDecoration(
                      color: darkTheme ? Colors.black : Colors.white,
                         borderRadius: BorderRadius.circular(10)
                     ),
                           child: Padding(
                            padding: const EdgeInsets.all(10),
                                child: Column(
                                    children: [
                                    Text(driverRideStatus,style: const TextStyle(fontWeight: FontWeight.bold,color: Colors.black),),
                                     const SizedBox(height: 5,),
                                       Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                                       const SizedBox(height: 5,),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                   Row(
                                                       children: [
                                                        Container(
                                                              padding: const EdgeInsets.all(10),
                                                          decoration: BoxDecoration(
                                                           color: darkTheme ? Colors.amber.shade400 : Colors.lightBlue,
                                                          borderRadius: BorderRadius.circular(10),
                                                           ),
                                                           child: Icon(Icons.person, color: darkTheme ? Colors.black : Colors.white,),
                                                           ),

                                                   const SizedBox(width: 5,),

                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                             children: [
                                                            Text(driverName,style: const TextStyle(fontWeight: FontWeight.bold,color: Colors.black),),
                                                               Text(driverPhone,style: const TextStyle(fontWeight: FontWeight.bold,color: Colors.black),),

                                                               Row(
                                                                         children: [
                                                                     const Icon(Icons.star,color: Colors.orange,),

                                                                    const SizedBox(width: 5,),

                                                                       Text("4", // == null ? "0.00" :double.parse(driverRatings).toStringAsFixed(2) ,
                                                                     style: const TextStyle(
                                                                      color: Colors.black
                                                               ),
                                                              ),
                                                        ],
                                                   )
                                                   ],
                                               )
                                             ],
                                    ),

    Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
    Image.asset("images/2389124.webp", scale: 3,),

    Text(driverAmbulanceDetails, style: const TextStyle(fontSize: 12),),
    ],
    )
    ],
    ),

    const SizedBox(height: 3,),

    Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
    ElevatedButton.icon(
    onPressed: () {
    _makePhoneCall("tell: $driverPhone");
    },
    style: ElevatedButton.styleFrom(backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue),
    icon: const Icon(Icons.phone),
    label: const Text("Call Driver"),
    ),

    ],
    ),
      ),
      )
            ),
        ]
    )
    )
    );

    }
  }
//  Positioned(
//   top: 40,
//   right: 20,
//  left: 20,
// child: Container(
//  decoration: BoxDecoration(
//   border: Border.all(color: Colors.black),
//   color: Colors.white
//   ),
//  padding: EdgeInsets.all(20),
//   child: Text(Provider.of<AppInfo>(context).userPickUpLocation !=null
//      ?(Provider.of<AppInfo>(context)).userPickUpLocation!.locationName!.substring(0,24) +"......."
//    : "Not Getting Address",

//  ),
//  ),
// ),