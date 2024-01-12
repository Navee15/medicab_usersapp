import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:medicab_usersapp/Authentication/signup_screen.dart';
import 'package:medicab_usersapp/splashScreen/splash_screen.dart';

import '../global/global.dart';
import '../widgets/progress_dialog.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailTextEditingController =TextEditingController();
  final passwordTextEditingController =TextEditingController();

  validateForm() {

     if (!emailTextEditingController.text.contains("@")) {
      Fluttertoast.showToast(msg: "Email is not valid");
    }
    else if (passwordTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Password is Mandatory.");
    }
    else {
     LoginuserNow();
    }
  }
  LoginuserNow() async{
    showDialog(context: context,
        barrierDismissible: false,
        builder: (BuildContext c)
        {
          return ProgressDialog(message: "processing, please wait",);
        }
    );
    final User? firebaseUser = (
        await fAuth.signInWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim(),
        ).catchError((msg) {
          Navigator.pop(context);
          Fluttertoast.showToast(msg:"Error: " + msg.toString());
        })
    ).user;
    if(firebaseUser !=null){

      currentUser=firebaseUser;
      Navigator.push(context, MaterialPageRoute(builder: (c)=>const MySplashScreen()));
      Fluttertoast.showToast(msg: "Login Successful");
    }
    else{
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Error occurred during Login");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 30,),
              Padding(
                padding:const EdgeInsets.all(20.0),
                child: Image.asset("images/2389124.webp"),
              ),
              const SizedBox(height: 10,),
              const Text("Login as a User",
                style:TextStyle(
                  fontSize:26,
                  color:Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                  controller: emailTextEditingController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                  decoration: const InputDecoration(
                    labelText: "EMAIL",
                    hintText: "EMAIL",

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
                    hintText: "Password",

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
              const SizedBox(height: 20,),
              ElevatedButton(
                  onPressed:  (){
                validateForm();
                  }, style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreenAccent,
              ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 18,

                    ),
                  ),
              ),
                 TextButton( child: const Text(
                   "Don't have an Account?Signup here",
                   style:TextStyle(color:Colors.grey),
                 ),
                   onPressed: (){
                   Navigator.push(context, MaterialPageRoute(builder: (c)=>const SignupScreen()));
                   },
                 ),
            ],
          ),
        ),
      ),
    );
  }
}
