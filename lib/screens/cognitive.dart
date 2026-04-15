import 'package:flutter/material.dart';

class CognitivePage extends StatelessWidget {

final List games = [

"Memory",
"Puzzle",
"Matching",
"Words",
"Numbers",
"Logic"

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

itemCount: games.length,

itemBuilder: (context,index){

return Container(

decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20)
),

child: Column(

mainAxisAlignment: MainAxisAlignment.center,

children: [

Icon(
Icons.extension,
size:40,
color: Colors.blue
),

SizedBox(height:10),

Text(games[index])

],

),

);

},

);

}
}