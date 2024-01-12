import 'package:flutter/material.dart';
import 'package:medicab_usersapp/mainScreens/rate_driver_screen.dart';

import '../splashScreen/splash_screen.dart';
class payFareAmountDialog extends StatefulWidget {
 double? fareAmount;
 payFareAmountDialog({this.fareAmount});
  @override
  State<payFareAmountDialog> createState() => _payFareAmountDialogState();
}

class _payFareAmountDialogState extends State<payFareAmountDialog> {
  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Dialog(

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      backgroundColor: Colors.transparent,
      child:Container(
        margin:const EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: darkTheme  ? Colors.black : Colors.blue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize:MainAxisSize.min ,
          children:[

            const SizedBox(height: 20,),

            Text("Fare Amount".toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkTheme ? Colors.amber.shade400 :Colors.white,
                fontSize: 16,
              ),
            ),

            const SizedBox(height:20,),

            Divider(
              thickness: 2,
              color: darkTheme ? Colors.amber.shade400 : Colors.white,
            ),

            const SizedBox(height: 10,),

            Text(
              "₹ " +widget.fareAmount.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkTheme ? Colors.amber.shade400 :Colors.white,
                fontSize: 50,
              ),
            ),

            const SizedBox(height: 10,),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                "This is the total trip fare Amount. Please Pay it to the driver",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkTheme ? Colors.amber.shade400 : Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10,),

            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkTheme ? Colors.amber.shade400 :Colors.white,
                ),
                onPressed: () {
                 // Future.delayed(const Duration(m),  (){
                    Navigator.pop(context,"Cash Paid");
                    Navigator.push(context, MaterialPageRoute(builder: (c)=> RateDriverScreen()));
                //  });
                },
                child: Row(
                  children:[
                    Text(
                      "Pay Cash",
                      style: TextStyle(
                        fontSize:20,
                        color: darkTheme ? Colors.black : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      " ₹ "+widget.fareAmount.toString(),
                      style:TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: darkTheme ? Colors.black : Colors.blue,

                      ),
                    ),
                  ],
                ),
              ),
            )
          ],

        ),
      ),
    );
  }
}
