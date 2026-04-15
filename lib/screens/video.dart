import 'package:flutter/material.dart';

class VideoPage extends StatelessWidget {

final String title;

VideoPage({required this.title});

@override
Widget build(BuildContext context) {

return Scaffold(

appBar: AppBar(
title: Text(title),
),

body: Padding(
padding: EdgeInsets.all(15),

child: Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: [

Container(
height:200,
color: Colors.grey,
child: Center(
child: Text("Video Here"),
),
),

SizedBox(height:20),

Text(
"Conseils",
style: TextStyle(
fontSize:18,
fontWeight: FontWeight.bold
),
),

SizedBox(height:10),

Text(
"Do this exercise daily to improve patient health."
)

],

),

),

);

}
}