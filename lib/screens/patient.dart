import 'package:flutter/material.dart';

class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {

int selectedIndex = 0;

List jour = [
"Lun","Mar","Mer","Jeu","Ven","Sam","Dim"
];

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xff8EA7BF),

body: SafeArea(
child: SingleChildScrollView(
child: Padding(
padding: const EdgeInsets.all(15),
child: Column(
children: [


SizedBox(
height:70,
child: ListView.builder(
scrollDirection: Axis.horizontal,
itemCount: 14,
itemBuilder: (context,index){

DateTime today = DateTime.now();
DateTime date = today.add(Duration(days: index));

List jour = [
"Lun","Mar","Mer","Jeu","Ven","Sam","Dim"
];


String day = jour[date.weekday - 1];
String number = date.day.toString();

return GestureDetector(
onTap: (){
setState(() {
selectedIndex = index;
});
},

child: dayCard(
day,
number,
selectedIndex == index,
),
);

},
),
),

const SizedBox(height:15),

/// Container
Container(
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
color: const Color(0xffAEBBD2),
borderRadius: BorderRadius.circular(25),
),

child: Column(
children: [

/// Title
Container(
height:60,
decoration: BoxDecoration(
color: const Color(0xff8799C7),
borderRadius: BorderRadius.circular(20),
),
child: const Center(
child: Text(
"Taches du jour",
style: TextStyle(
fontSize:20,
fontWeight: FontWeight.bold,
),
),
),
),

const SizedBox(height:20),

taskCard(
"Prendre les médicaments",
Colors.indigo,
[
"08:00 Médicaments du matin",
"09:00 Vérifier alarme",

],
"assets/medicine.png"
),

const SizedBox(height:15),

taskCard(
"Repas équilibré",
Colors.orange,
[
"08:30 Petit-déjeuner",
"13:00 Déjeuner",
"15:00 Boire eau"
],
"assets/food.png"
),

const SizedBox(height:15),

taskCard(
"Activité physique légère",
Colors.green,
[
"10:00 Marche",
"10:30 Exercices",

],
"assets/sport.png"
),

const SizedBox(height:15),

taskCard(
"Activité cognitive",
Colors.lime,
[
"16:00 Jeu mémoire",
"16:30 Lecture",
"17:00 Conversation"
],
"assets/brain.png"
),

const SizedBox(height:15),

taskCard(
"Prendre médicaments",
Colors.purple,
[
"20:00 Médicaments soir",
"20:15 Vérifier",

],
"assets/medicine.png"
),

],
),
)

],
),
),
),
),

bottomNavigationBar: Container(
height:70,
decoration: BoxDecoration(
color: Colors.grey[300],
borderRadius: const BorderRadius.only(
topLeft: Radius.circular(20),
topRight: Radius.circular(20),
),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: const [

Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.home),
Text("Home")
],
),

Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.person),
Text("Profile")
],
),

Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.phone),
Text("Help")
],
),

],
),
),

);
}

/// Day Card

Widget dayCard(
String day,
String number,
bool active
){
return Container(
width:75,
margin: const EdgeInsets.symmetric(horizontal:6),
decoration: BoxDecoration(
color: active ? Colors.blue : Colors.transparent,
borderRadius: BorderRadius.circular(15),
),

child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [

Text(
day,
style: TextStyle(
fontWeight: FontWeight.bold,
color: active ? Colors.white : Colors.black,
),
),

const SizedBox(height:5),

Text(
number,
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize:16,
color: active ? Colors.white : Colors.black,
),
),

],
),
);
}

/// Task Card

Widget taskCard(
String title,
Color color,
List<String> list,
String image,
){
return Container(
decoration: BoxDecoration(
color: Colors.grey[300],
borderRadius: BorderRadius.circular(20),
),

child: Column(
children: [

Container(
height:45,
decoration: BoxDecoration(
color: color,
borderRadius: const BorderRadius.only(
topLeft: Radius.circular(20),
topRight: Radius.circular(20),
),
),
child: Center(
child: Text(
title,
style: const TextStyle(
color: Colors.white,
fontSize:16,
fontWeight: FontWeight.bold,
),
),
),
),

Padding(
padding: const EdgeInsets.all(12),
child: Row(
children: [

Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: list
.map((e) => Padding(
padding: const EdgeInsets.symmetric(vertical:4),
child: Text(
e,
style: const TextStyle(
fontSize:14,
fontWeight: FontWeight.w500,
),
),
))
.toList(),
),
),

Image.asset(
image,
height:70,
)

],
),
)

],
),
);
}

}