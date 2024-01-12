// ignore_for_file: body_might_complete_normally_catch_error

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:medicab_usersapp/Authentication/login_screen.dart';
import 'package:medicab_usersapp/splashScreen/splash_screen.dart';

import '../global/global.dart';
import '../widgets/progress_dialog.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameTextEditingController =TextEditingController();
  final emailTextEditingController =TextEditingController();
  final phoneTextEditingController =TextEditingController();
  final passwordTextEditingController =TextEditingController();
validateForm() {
  if (nameTextEditingController.text.length < 3) {
    Fluttertoast.showToast(msg: "name must be at least 3 characters.");
  }
  else if (!emailTextEditingController.text.contains("@")) {
    Fluttertoast.showToast(msg: "Email is not valid");
  }

  else if (phoneTextEditingController.text.isEmpty) {
    Fluttertoast.showToast(
        msg: "Phone number is mandatory and should be 10 number.");
  }
  else if (passwordTextEditingController.text.length < 6) {
    Fluttertoast.showToast(msg: "Password must be at least 6 characters .");
  }
  else {
  saveUserInfoNow();
  }
}
saveUserInfoNow() async{
  showDialog(context: context,
      barrierDismissible: false,
      builder: (BuildContext c)
  {
    return ProgressDialog(message: "processing, please wait",);
  }
  );
  final User? firebaseUser = (
      await fAuth.createUserWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim(),
      ).catchError((msg){
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Error: $msg");
      })
  ).user;
  if(firebaseUser !=null){
   Map usersMap =
   {
     "id":firebaseUser.uid,
     "name":nameTextEditingController.text.trim(),
     "email":emailTextEditingController.text.trim(),
     "phone":phoneTextEditingController.text.trim(),
   };
  DatabaseReference driversRef = FirebaseDatabase.instance.ref().child("users");
   driversRef.child(firebaseUser.uid).set(usersMap);
   currentUser=firebaseUser;
   Navigator.push(context, MaterialPageRoute(builder: (c)=>const MySplashScreen()));
   Fluttertoast.showToast(msg: "Account has been created");
  }
  else{
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Account has not been created");
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 10,),
              Padding(
              padding:const EdgeInsets.all(20.0),
             child: Image.asset("images/2389124.webp"),
              ),
              const SizedBox(height: 10,),
              const Text("Register as a User",
                style:TextStyle(
                  fontSize:26,
                  color:Colors.grey,
                  fontWeight: FontWeight.bold,
                    ),
              ),
              TextField(
                controller: nameTextEditingController,
                style: const TextStyle(
                  color: Colors.grey,
                ),
                decoration: const InputDecoration(
                  labelText: "Name",
                  hintText: "at least 3 characters",

                  enabledBorder:UnderlineInputBorder(
                    borderSide: BorderSide(color:Colors.grey)
                  ),
                    focusedBorder:UnderlineInputBorder(
                borderSide: BorderSide(color:Colors.grey)
              ),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 10
                  ),
                  labelStyle:TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                  ),
                  prefix: Icon(Icons.person,color: Colors.grey,)

      )
              ),
              TextField(
                  controller: emailTextEditingController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                  decoration: const InputDecoration(
                    labelText: "EMAIL",
                    hintText: "enter a valid email",

                    enabledBorder:UnderlineInputBorder(
                        borderSide: BorderSide(color:Colors.grey)
                    ),
                    focusedBorder:UnderlineInputBorder(
                        borderSide: BorderSide(color:Colors.grey)
                    ),
                    hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 10
                    ),
                    labelStyle:TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),

                  )
              ),
              TextField(
                  controller: phoneTextEditingController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                  decoration: const InputDecoration(
                    labelText: "Phone",
                    hintText: "Phone",

                    enabledBorder:UnderlineInputBorder(
                        borderSide: BorderSide(color:Colors.grey)
                    ),
                    focusedBorder:UnderlineInputBorder(
                        borderSide: BorderSide(color:Colors.grey)
                    ),
                    hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 10
                    ),
                    labelStyle:TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),

                  )
              ),
              TextField(
                  controller: passwordTextEditingController,
                  keyboardType: TextInputType.text,
                  obscureText: true,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                  decoration: const InputDecoration(
                    labelText: "Password",
                    hintText: "at least 6 characters",

                    enabledBorder:UnderlineInputBorder(
                        borderSide: BorderSide(color:Colors.grey)
                    ),
                    focusedBorder:UnderlineInputBorder(
                        borderSide: BorderSide(color:Colors.grey)
                    ),
                    hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 10
                    ),
                    labelStyle:TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),

                  )
              ),
              const SizedBox(height: 15,),
              ElevatedButton(
                onPressed: ()
              {
              validateForm();
              },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreenAccent,
                  ),
                  child: const Text(
                "Create Account",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 18,

                ),
              ),
              ),
              TextButton( child: const Text(
                "Already have an Account? Login here",
                style:TextStyle(color:Colors.grey),
              ),
                onPressed: (){

                  Navigator.push(context, MaterialPageRoute(builder: (c)=>const LoginScreen()));
                },
              ),

            ],

          ),
        ),
      )
    );
  }
}
