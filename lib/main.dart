
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:medicab_usersapp/splashScreen/splash_screen.dart';
import 'package:medicab_usersapp/themeProvider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'infoHandler/app_info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp( const MyApp());

}

class MyApp extends StatefulWidget
{

   const MyApp({super.key});

  static void restartApp(BuildContext context){
    context.findAncestorStateOfType<_State>()!.restartApp();

  }
  @override
  State createState() => _State();
}

class _State extends State<MyApp> {
  Key key=UniqueKey();
  void restartApp(){
    setState(() {
      key =UniqueKey();
    });
  }
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child: MaterialApp(
        title: 'Flutter Demo',
        themeMode: ThemeMode.system,
        theme: MyThemes.lightTheme,
        darkTheme: MyThemes.darkTheme,
        debugShowCheckedModeBanner: false,
        home:  const MySplashScreen(),
      ),
    );
  }
}


