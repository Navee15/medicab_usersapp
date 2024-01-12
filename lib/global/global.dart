import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicab_usersapp/Models/direction_details_info.dart';

import '../Models/usermodel.dart';

final FirebaseAuth fAuth = FirebaseAuth.instance;
User? currentUser;



UserModel? userModelCurrentInfo;
List driversList =[];
String cloudMessagingServerToken = "key=AAAAA2BlPGQ:APA91bFXwa0fWPg8hsriNhxLf5zUI_njN96pUP6cldNh6FQYT6IihB5or3oiRNbZz8IUfeter-D_JbXSv-zwci2RI1q2svMxUUgM09Yyccb3eNXvKZ5lYQjHik-fK0YI44PU_2YpItU1";

DirectionDetailsInfo? tripDirectionDetailsInfo;
String userDropOffAddress ="";
String driverAmbulanceDetails="";
String driverName="";
String driverPhone="";
String driverRatings="";
double countRatingStars=0.0;
String tittleStarsRating="";
