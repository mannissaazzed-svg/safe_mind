import 'package:flutter/material.dart';
import 'home.dart';
import 'medicine_form.dart';


class PatientForm extends StatefulWidget {
  const PatientForm({super.key});

  @override
  State<PatientForm> createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {

final _formKey = GlobalKey<FormState>();

TextEditingController nom = TextEditingController();
TextEditingController age = TextEditingController();
TextEditingController medicaments = TextEditingController();

String maladie = "Parkinson";
String genre = "Homme";

bool tremblement = false;
bool memoire = false;
bool mouvement = false;

@override
Widget build(BuildContext context) {
return Scaffold(

backgroundColor: const Color(0xffE9F2FB),

appBar: AppBar(
backgroundColor: Colors.blue,
title: const Text("Formulaire médical"),
centerTitle: true,
),

body: SingleChildScrollView(

child: Padding(
padding: const EdgeInsets.all(15),

child: Form(
key: _formKey,

child: Column(
children: [

/// IMAGE PROFILE

const SizedBox(height:10),

CircleAvatar(
radius:50,
backgroundColor: Colors.blue,
child: CircleAvatar(
radius:46,
backgroundImage: AssetImage(
"assets/patient.png"
),
),
),

const SizedBox(height:20),

/// Patient Information

buildSection(
"Informations patient",
Column(
children: [

buildText("Nom"),
buildField(nom),

buildText("Age"),
buildField(age),

const SizedBox(height:10),

/// Gender

buildText("Genre"),

Row(
children: [

Expanded(
child: RadioListTile(
title: const Text("Homme"),
value: "Homme",
groupValue: genre,
onChanged: (value){
setState(() {
genre = value!;
});
},
),
),

Expanded(
child: RadioListTile(
title: const Text("Femme"),
value: "Femme",
groupValue: genre,
onChanged: (value){
setState(() {
genre = value!;
});
},
),
),

],
)

],
)
),

/// Medical Information

buildSection(
"Informations Médical",
Column(
children: [

DropdownButtonFormField(
value: maladie,
items: const [

DropdownMenuItem(
value: "Parkinson",
child: Text("Parkinson"),
),

DropdownMenuItem(
value: "Alzheimer",
child: Text("Alzheimer"),
),

],
onChanged: (value){
setState(() {
maladie=value!;
});
},
),

],
)
),

/// Symptoms

buildSection(
"Symptoms",
Column(
children: [

CheckboxListTile(
value: tremblement,
title: const Text("Tremblement"),
onChanged: (value){
setState(() {
tremblement=value!;
});
},
),

CheckboxListTile(
value: memoire,
title: const Text("Problème mémoire"),
onChanged: (value){
setState(() {
memoire=value!;
});
},
),

CheckboxListTile(
value: mouvement,
title: const Text("Problème mouvement"),
onChanged: (value){
setState(() {
mouvement=value!;
});
},
),

],
)
),

/// Médicaments

buildSection(
"Médicaments",
Column(
children: [

ElevatedButton.icon(

style: ElevatedButton.styleFrom(
backgroundColor: Colors.blue
),

onPressed: (){
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const MedicineForm()
)
);
},

icon: const Icon(Icons.medication),

label: const Text("Ajouter Médicament"),

)

],
)
),

const SizedBox(height:20),

/// Button

SizedBox(
width: double.infinity,

child:ElevatedButton(

style: ElevatedButton.styleFrom(
backgroundColor: Colors.blue,
padding: const EdgeInsets.all(15),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10)
)
),

onPressed: () {

Navigator.push(
context,
MaterialPageRoute(
builder: (context) => Home(),
)
);

},

child: const Text("Continue"),

)

)

],
),

),
),

),

);

}

/// Section

Widget buildSection(String title, Widget child){

return Container(

margin: const EdgeInsets.only(bottom:20),

decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(10),
boxShadow: [
BoxShadow(
color: Colors.grey.shade300,
blurRadius:5
)
]
),

child: Column(

children: [

Container(
width: double.infinity,
padding: const EdgeInsets.all(10),
decoration: const BoxDecoration(
color: Colors.blue,
borderRadius: BorderRadius.only(
topLeft: Radius.circular(10),
topRight: Radius.circular(10),
)
),

child: Text(
title,
style: const TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold
),
),
),

Padding(
padding: const EdgeInsets.all(10),
child: child,
)

],

),

);

}

/// Field

Widget buildField(controller){

return Padding(
padding: const EdgeInsets.only(bottom:10),

child: TextFormField(
controller: controller,
decoration: const InputDecoration(
border: OutlineInputBorder()
),
),

);

}

/// Text

Widget buildText(String text){

return Align(
alignment: Alignment.centerLeft,
child: Padding(
padding: const EdgeInsets.only(bottom:5),
child: Text(
text,
style: const TextStyle(
fontWeight: FontWeight.bold
),
),
),
);

}
}