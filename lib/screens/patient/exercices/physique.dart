import 'package:flutter/material.dart';
import 'video.dart';

class PhysicalPage extends StatelessWidget {

final List exercises = [

"Walking",
"Balance",
"Stretching",
"Hand Exercise",
"Breathing",
"Relaxation"

];

@override
Widget build(BuildContext context) {

return GridView.builder(

padding: EdgeInsets.all(15),

gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2,
crossAxisSpacing: 15,
mainAxisSpacing: 15
),

itemCount: exercises.length,

itemBuilder: (context,index){

return GestureDetector(

onTap:(){

Navigator.push(
context,
MaterialPageRoute(
builder: (context)=> VideoPage(
title: exercises[index],
)
)
);

},

child: Container(

decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20)
),

child: Column(

mainAxisAlignment: MainAxisAlignment.center,

children: [

Icon(
Icons.fitness_center,
size:40,
color: Colors.blue
),

SizedBox(height:10),

Text(exercises[index])

],

),

),

);

},

);

}
}