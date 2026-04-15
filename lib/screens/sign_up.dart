import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safemind/screens/person.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
bool obscure1 = true;
bool obscure2 = true;

@override
Widget build(BuildContext context) {

return Scaffold(

body: Container(

width: double.infinity,
height: double.infinity,

decoration: const BoxDecoration(

gradient: LinearGradient(

begin: Alignment.topCenter,
end: Alignment.bottomCenter,

colors: [
    Color(0xff9F9999),
    Color(0xff467FB3),

]

),

),

child: SafeArea(
child: SingleChildScrollView(
child: Column(

children: [

const SizedBox(height:40),

/// Title

const Text(
"Créez votre compte",
style: TextStyle(
fontSize:30,
color: Colors.white,
fontWeight: FontWeight.bold,
fontFamily: "Serif"
),
),

const SizedBox(height:30),

/// Form Container

Container(

padding: const EdgeInsets.all(25),

decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [
  Color(0xffB7BCC0), 
  Color(0xff559ACA),

],
),

borderRadius: BorderRadius.only(
topLeft: Radius.circular(40),
topRight: Radius.circular(40),
),

),

child: Column(

children: [

const SizedBox(height:20),

/// Username

buildField(
icon: Icons.person,
hint: "Nom d'utilisateur",
),

const SizedBox(height:20),

/// Email

buildField(
icon: Icons.email,
hint: "Téléphone ou Email",
),

const SizedBox(height:20),

/// Password

buildField(
icon: Icons.lock,
hint: "Mot de passe",
isPassword: true,
obscure: obscure1,
onTap: (){
setState(() {
obscure1 = !obscure1;
});
},
),

const SizedBox(height:20),

/// Confirm Password

buildField(
icon: Icons.lock,
hint: "Confirmez le mot de passe",
isPassword: true,
obscure: obscure2,
onTap: (){
setState(() {
obscure2 = !obscure2;
});
},
),

const SizedBox(height:30),

/// Button
GestureDetector(
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Person(),
                            ),
                          );
                        },
                        child: Container(
                          width: 220,
                          height: 50,

                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xffF37D7D),
                                Color(0xff594444),
                              ],
                            ),
                          ),

                          child: const Center(
                            child: Text(
                              "S'inscrire",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),


const SizedBox(height:20),

const Text(
"Ou inscrivez-vous en utilisant",
style: TextStyle(
color: Colors.white,
fontSize:16
),
),

const SizedBox(height:15),

/// Social Icons
Row(

mainAxisAlignment:
MainAxisAlignment.center,

children: [

socialIcon(
FontAwesomeIcons.apple,
Colors.black
),

const SizedBox(width:20),

socialIcon(
FontAwesomeIcons.google,
Colors.red
),

const SizedBox(width:20),

socialIcon(
FontAwesomeIcons.facebook,
Colors.blue
),

],

),

const SizedBox(height:20),

],

),

),

],

),

),
),

),

);

}



Widget buildField({

required IconData icon,
required String hint,
bool isPassword = false,
bool obscure = false,
VoidCallback? onTap,

}){

return Container(

padding: const EdgeInsets.symmetric(
horizontal:20),

height:60,

decoration: BoxDecoration(

color: Colors.white,

borderRadius:
BorderRadius.circular(20),

boxShadow: [

BoxShadow(
color: Colors.black12,
blurRadius:10,
offset: Offset(0,4)
)

],

),

child: Row(

children: [

Icon(icon),

const SizedBox(width:15),

Expanded(

child: TextField(

obscureText: obscure,

decoration: InputDecoration(
border: InputBorder.none,
hintText: hint,
),

),

),

if(isPassword)

GestureDetector(

onTap: onTap,

child: Icon(
obscure
? Icons.visibility_off
: Icons.visibility,
),

)

],

),

);

}

/// Social Icon

Widget socialIcon(IconData icon, Color color){

return Container(

padding: const EdgeInsets.all(12),

decoration: BoxDecoration(

color: Colors.white,

shape: BoxShape.circle,

boxShadow: [

BoxShadow(
color: Colors.black12,
blurRadius: 8
)

]

),

child: Icon(
icon,
color: color,
size: 22,
),

);

}

}