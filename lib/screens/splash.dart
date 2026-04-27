import 'package:flutter/material.dart';
import 'package:safemind/screens/patient/exercices/activites.dart';
import 'package:safemind/screens/soignant/caregiver.dart';
import 'package:safemind/screens/soignant/formulaire.dart';
import 'package:safemind/screens/patient/home.dart';
import 'package:safemind/screens/login.dart';
import 'package:safemind/screens/patient/medicaments.dart';
import 'package:safemind/screens/patient/nutrition.dart';
import 'package:safemind/screens/patient/patient.dart';
import 'package:safemind/screens/person.dart';
import 'package:safemind/screens/profile.dart';
import 'package:safemind/screens/sign_up.dart';
import 'package:safemind/screens/soignant/tasks.dart';
import 'package:safemind/screens/tracking.dart';
import 'package:safemind/services/auth/auth_gate.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}



class _SplashState extends State<Splash> {

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff5c9bd5),
              Colors.grey,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              ClipRRect(
  borderRadius: BorderRadius.circular(30),
  child: Image.asset(
    "assets/neuro.jpg",
    width: 120,
    height: 120,
    fit: BoxFit.cover,
  ),
),
              const SizedBox(width: 10),

              const Text(
                "SAFEMIND",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 2,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
