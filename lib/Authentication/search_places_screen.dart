import'package:flutter/material.dart';
import 'package:medicab_usersapp/Models/predicted_places.dart';

import '../Assistants/request_assistant.dart';
import '../global/Map_key.dart';
import '../widgets/place_prediction_tile.dart';

class SearchPlacesScreen extends StatefulWidget {
  const SearchPlacesScreen({super.key});

  @override
  State<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

 class _SearchPlacesScreenState extends State<SearchPlacesScreen> {

  List<PredictedPlaces> placesPredictedList = [];

  findPlaceAutoCompleteSearch(String inputText) async{
    if(inputText.length>1){
      String urlAutoCompleteSearch = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$inputText&key=$mapKey&components=country:IN";

      var responseAutoCompleteSearch = await RequestAssistant.recieveRequest(urlAutoCompleteSearch);

      if(responseAutoCompleteSearch == "Error occurred, Failed. NO Response."){
        return;
      }

      if(responseAutoCompleteSearch["status"]=="OK"){
        var placePredictions = responseAutoCompleteSearch["predictions"];


        var placePredictionsList = (placePredictions as List).map((jsonData) =>PredictedPlaces.fromJson(jsonData)).toList();

        setState(() {
          placesPredictedList = placePredictionsList;
        });
      }
    }
  }
    @override
    Widget build(BuildContext context) {

      bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

      return GestureDetector(
          onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
      backgroundColor: darkTheme ? Colors.black : Colors.white,
      appBar: AppBar(
      backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
      leading: GestureDetector(
      onTap: () {
      Navigator.pop(context);
      },
      child: Icon(Icons.arrow_back, color: darkTheme ? Colors.black : Colors.white,),
      ),
      title: Text(
      "Search & Set DropOff "
          "Location",
      style: TextStyle(color: darkTheme ? Colors.black : Colors.white),
      ),
      elevation: 0.0,
      ),
      body: Column(
      children: [
      Container(
      decoration: BoxDecoration(
      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
      boxShadow: const[
      BoxShadow(
      color: Colors.white54,
      blurRadius: 8,
      spreadRadius: 0.5,
      offset: Offset(
      0.7,
      0.7,
      )
      )
      ],
      ),
        child: Padding(
        padding:const EdgeInsets.all(10.0),
        child: Column(
        children: [
          Row(
      children: [
      Icon(
      Icons.adjust_sharp,
      color: darkTheme ? Colors.black : Colors.white,
      ),

      const SizedBox(height: 18.0,),

      Expanded(
      child: Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
      onChanged: (value) {
             findPlaceAutoCompleteSearch(value);
      },
      decoration: InputDecoration(
      hintText: "Search Location here....",
      fillColor: darkTheme ? Colors.black : Colors.white54,
      filled: true,
      border: InputBorder.none,
      contentPadding:const EdgeInsets.only(
      left: 11,
      top: 8,
      bottom: 8,
      )
      ),
      ),
      ),
      )
      ],
      )
      ],
      ),
      ),
      ),

      //display place predictions Result
      (placesPredictedList.isNotEmpty)
      ? Expanded(
      child: ListView.separated(
      itemCount:placesPredictedList.length,
      physics: const ClampingScrollPhysics(),
      itemBuilder:(context,index){
      return PlacePredictionTileDesign(
      predictedPlaces: placesPredictedList[index],
      );
    },
        separatorBuilder: (BuildContext context,int index){
              return Divider(
              height: 0,
           color: darkTheme ? Colors.amber.shade400 : Colors.blue,
           thickness: 0,
              );
        },
               ),
             ): Container(),
      ],
      ),
      ),

      );

    }

    }
