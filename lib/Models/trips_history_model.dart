import 'package:firebase_database/firebase_database.dart';

class TripsHistoryModel{
  String? time;
  String? originAddress;
  String? destinationAddress;
  String? status;
  String? fareAmount;
  String? Ambulance_Details;
  String? driverName;
  String? ratings;

  TripsHistoryModel({
    this.time,
    this.originAddress,
    this.destinationAddress,
    this.status,
    this.fareAmount,
    this.Ambulance_Details,
    this.driverName,
    this.ratings,
});
  TripsHistoryModel.fromSnapshot(DataSnapshot dataSnapshot){
    time=(dataSnapshot.value as Map)["time"];
    originAddress=(dataSnapshot.value as Map)["originAddress"];
    destinationAddress=(dataSnapshot.value as Map)["destinationAddress"];
    status=(dataSnapshot.value as Map)["status"];
    fareAmount=(dataSnapshot.value as Map)["fareAmount"];
    Ambulance_Details=(dataSnapshot.value as Map)["Ambulance_Details"];
    driverName=(dataSnapshot.value as Map)["driverName"];
    ratings=(dataSnapshot.value as Map)["ratings"];


  }
}