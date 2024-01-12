import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medicab_usersapp/Assistants/assistant_methods.dart';

import '../Authentication/login_screen.dart';
import '../global/global.dart';
import '../mainScreens/main_screen.dart';
class MySplashScreen extends StatefulWidget
{
  const MySplashScreen({super.key});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen>
{startTimer(){
  Timer(const Duration(seconds:3), ()async
  {

    if(await fAuth.currentUser != null){
      fAuth.currentUser !=null ?AssistantMethods.readcurrentOnlineuserInfo():null;
      currentUser=fAuth.currentUser;

      Navigator.push(context,MaterialPageRoute(builder: (c)=>const MainScreen()));

    }
    else{
      Navigator.push(context,MaterialPageRoute(builder: (c)=>const LoginScreen()));
    }
  });
}
@override
void initState() {

  super.initState();
  startTimer();
}
@override
Widget build(BuildContext context) {
  return Material(
    child: Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("images/2389124.webp"),
            const SizedBox(height: 10,),
            const Text(
                "MEDICAB USER APP",
                style: TextStyle(
                    fontSize: 25,
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                )
            )

          ],
        ),

      ),
    ),
  );
}
}
