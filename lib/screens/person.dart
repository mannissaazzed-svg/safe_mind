import 'package:flutter/material.dart';
import 'package:safemind/screens/formulaire.dart';
import 'patient.dart';


class Person extends StatelessWidget {
  const Person({super.key});

  @override
  Widget build(BuildContext context) {
    
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xffB7BCC0),
              Color(0xff559ACA),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              
              SizedBox(height: screenHeight * 0.04),

              
              const Text(
                "Qui ètes vous ?\nchoisissez-vous vous-mème\npour commencer avec cette application",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    
                    Positioned.fill(
                      top: 50, 
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/pngtree.jpg"),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            topRight: Radius.circular(50),
                          ),
                        ),
                      ),
                    ),

                    
                    Positioned(
                      top: -40, 
                      right: 20,
                      child: Image.asset(
                        "assets/int.png",
                        height: screenHeight * 0.16, 
                      ),
                    ),

                   
                    Positioned(
                      top: 100, 
                      left: 30,
                      right: 30,
                      bottom: 30,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildButton("MEDECIN", context),
                          buildButton("PATIENT", context),
                          buildButton("AIDE SOIGNANT", context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildButton(String text, BuildContext context) {
    return GestureDetector(
     

      onTap: () {

        /// PATIENT
        if (text == "PATIENT") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PatientPage(),
            ),
          );
        }

        /// AIDANT / COMPANION
        if (text == "AIDE SOIGNANT") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PatientForm(),
            ),
          );
        }

      },



      child: Container(
        width: double.infinity,
        
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:safemind/screens/formulaire.dart';
import 'patient.dart';
import 'home.dart';

class Person extends StatelessWidget {
  const Person({super.key});

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
              Color(0xff9E9E9E),
              Color(0xff467EB3),
            ],
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 40),

              /// Text
              const Text(
                "Who you are?\nchoose yourself to start\nwith this app",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Stack(
                  children: [

                    /// Background Image
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Image.asset(
                        "assets/pngtree.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),

                    /// Buttons
                    Positioned(
                      top: 160,
                      left: 30,
                      right: 30,
                      child: Column(
                        children: [

                          buildButton("DOCTOR", context),

                          const SizedBox(height: 30),

                          buildButton("Patient\nCompanion", context),

                          const SizedBox(height: 30),

                          buildButton("PATIENT", context),

                        ],
                      ),
                    ),

                    /// Character Image
                    Positioned(
                      right: 20,
                      top: 0,
                      child: Image.asset(
                        "assets/int.png",
                        height: 150,
                      ),
                    ),

                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget buildButton(String text, BuildContext context) {
    return GestureDetector(

      onTap: () {

        /// PATIENT
        if (text == "PATIENT") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PatientPage(),
            ),
          );
        }

        /// AIDANT / COMPANION
        if (text == "Patient\nCompanion") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PatientForm(),
            ),
          );
        }

      },

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 25),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black26,
              offset: Offset(0, 4),
            )
          ],
        ),

        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
*/