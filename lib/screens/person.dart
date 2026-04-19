import 'package:flutter/material.dart';
import 'package:safemind/screens/soignant/formulaire.dart';
import 'package:safemind/screens/patient/home.dart';

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
              SizedBox(height: screenHeight * 0.05),

              const Text(
                "Qui ètes vous ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Sélectionnez votre profil pour commencer",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),

              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    
                   
                    Positioned.fill(
                      top: 70, 
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 15,
                              offset: Offset(0, -5),
                            )
                          ],
                        ),
                      ),
                    ),

                    
                    Positioned(
                      top: -40, 
                      right: 20, 
                      child: SizedBox(
                        height: screenHeight * 0.20,
                        child: Image.asset(
                          "assets/int.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                   
                    Positioned(
                      top: 140, 
                      left: 30,
                      right: 30,
                      bottom: 60,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          buildButton("MÉDECIN", context),
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
      if (text == "PATIENT") {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const Home()));
      }
      if (text == "AIDE SOIGNANT") {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientForm()));
      }
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900, 
            color: Colors.black,
            letterSpacing: 1.5,
          ),
        ),
      ),
    ),
  );
}
}




