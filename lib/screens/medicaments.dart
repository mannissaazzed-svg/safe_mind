import 'package:flutter/material.dart';

class MedicinesPage extends StatefulWidget {
  const MedicinesPage({super.key});

  @override
  State<MedicinesPage> createState() => _MedicinesPageState();
}

class _MedicinesPageState extends State<MedicinesPage> {

  int jour_selectionne = 0;

  TextEditingController searchController = TextEditingController();

  List days = [
    "4\nSam",
    "5\nDim",
    "6\nLun",
    "7\nMar",
    "8\nMer",
    "9\nJeu",
    "10\nVen"
  ];

  List medicines = [
    {
      "image":"assets/donepezil.png",
      "text":"Médicament:Donepezil\nDose: 5 mg 10mg\nFréquence: 1fois par jour"
    },
    {
      "image":"assets/rivastigmine.png",
      "text":"Médicament: Rivastigmine\nDose: 1.5 mg 6mg\nFréquence: 2fois par jour"
    },
    {
      "image":"assets/zeyzelf.png",
      "text":"Médicament:Rivastigmine(Patch)\nDose: 4.6 mg 9.5mg\nFréquence: 1fois par jour"
    },
    {
      "image":"assets/galantamine.png",
      "text":"Médicament:Galentamine\nDose: 4 mg 12mg\nFréquence: 2fois par jour"
    },
  ];

  List filteredMedicines = [];

  @override
  void initState() {
    super.initState();
    filteredMedicines = medicines;
  }

  void searchMedicine(String query){
    final suggestions = medicines.where((medicine){

      final text = medicine["text"].toLowerCase();
      final input = query.toLowerCase();

      return text.contains(input);

    }).toList();

    setState(() {
      filteredMedicines = suggestions;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

backgroundColor: const Color(0xff8EA7BF),

body: SafeArea(
child: SingleChildScrollView(
child: Column(
children: [

/// Top Bar
Padding(
padding: const EdgeInsets.all(15),
child: Row(
children: [

/// Back
GestureDetector(
onTap: (){
Navigator.pop(context);
},
child: const Icon(Icons.arrow_back,size:28),
),

const SizedBox(width:10),

/// Search
Expanded(
child: Container(
height:40,
decoration: BoxDecoration(
color: Colors.grey[300],
borderRadius: BorderRadius.circular(20),
),

child: TextField(
controller: searchController,
onChanged: searchMedicine,
decoration: const InputDecoration(
border: InputBorder.none,
prefixIcon: Icon(Icons.search),
hintText: "Rechercher médicament",
),
),

),
),

const SizedBox(width:10),

],
),
),

/// Image + Title
Padding(
padding: const EdgeInsets.symmetric(horizontal:15),
child: Row(
children: [

Image.asset(
"assets/pharmacy.png",
height:120,
),

const SizedBox(width:20),

const Text(
"Médicaments",
style: TextStyle(
fontSize:24,
fontWeight: FontWeight.bold,
),
)

],
),
),

const SizedBox(height:20),

/// Days
SizedBox(
height:70,
child: ListView.builder(
scrollDirection: Axis.horizontal,
itemCount: days.length,
itemBuilder: (context,index){

return GestureDetector(
onTap: (){
setState(() {
jour_selectionne = index;
});
},
child: Container(
margin: const EdgeInsets.symmetric(horizontal:8),
width:55,
decoration: BoxDecoration(
color: jour_selectionne == index
? Colors.red[300]
: Colors.grey[300],
borderRadius: BorderRadius.circular(20),
),
child: Center(
child: Text(
days[index],
textAlign: TextAlign.center,
style: const TextStyle(
fontWeight: FontWeight.bold),
),
),
),
);

}),
),

const SizedBox(height:20),

/// Medicines List

...filteredMedicines.map((medicine){

return medicineCard(
medicine["image"],
medicine["text"],
);

}).toList(),

const SizedBox(height:20),

],
),
),
),

);
}

/// Card

Widget medicineCard(image,text){
return Padding(
padding: const EdgeInsets.all(12),
child: Container(
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
color: const Color.fromARGB(255, 205, 200, 200),
borderRadius: BorderRadius.circular(25),
),
child: Row(
children: [

Image.asset(
image,
height:80,
),

const SizedBox(width:20),

Expanded(
child: Text(
text,
style: const TextStyle(
fontSize:15,
fontWeight: FontWeight.w500,
),
),
)

],
),
),
);
}

}