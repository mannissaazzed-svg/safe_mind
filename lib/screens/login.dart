import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'sign_up.dart';
import 'person.dart';


class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool isHidden = true;

  signUp() async {

  try {

    final response = await Supabase.instance.client.auth.signUp(
      email: email.text.trim(),
      password: password.text.trim(),
    );

    if (response.user != null) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const Person(),
        ),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la création du compte"),
        ),
      );

    }

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
      ),
    );

  }

}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff9F9999),
              Color(0xff467FB3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [

                const SizedBox(height: 80),

                const Text(
                  "Bienvenue",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 60),

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
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),

                  child: Column(
                    children: [

                      /// Email
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: TextField(
                          controller: email,
                          decoration: InputDecoration(
                            hintText: "Adresse email",
                            prefixIcon: Icon(Icons.email),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Password
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: TextField(
                          controller: password,
                          obscureText: isHidden,
                          decoration: InputDecoration(
                            hintText: "Mot de passe",
                            prefixIcon: const Icon(Icons.lock),

                            suffixIcon: IconButton(
                              icon: Icon(
                                isHidden
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: (){
                                setState(() {
                                  isHidden = !isHidden;
                                });
                              },
                            ),

                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text("Mot de passe oublié?"),
                      ),

                      const SizedBox(height: 40),

                      /// Sign In Button
                     SizedBox(
                        width: 220,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (){
                            signUp();
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.zero,
                          ),

                          child: Ink(
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
                      ),

                      const SizedBox(height: 20),

                      const Text("Ou connectez-vous avec"),

                      const SizedBox(height: 20),

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

                      const SizedBox(height: 30),

                      /// SignUp Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          const Text(
                            "Vous n'avez pas de compte?",
                          ),

                          GestureDetector(
                            onTap: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignInPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "S'inscrire",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        ],
                      ),

                      const SizedBox(height: 20),

                    ],
                  ),
                )

              ],
            ),
          ),
        ),
      ),
    );
  }


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

/*
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'sign_up.dart';
import 'person.dart';


class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool isHidden = true;

  signUp() async{
    final response = await Supabase.instance.client.auth.signUp(
      email: email.text,
      password: password.text
    );
    if (response.error == null){
      print("Success");

    } else {
      print("error:${response.error!.message}");
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff9F9999),
              Color(0xff467FB3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [

                const SizedBox(height: 80),

                const Text(
                  "Bienvenue",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 60),

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
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),

                  child: Column(
                    children: [

                      /// Email
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: TextField(
                          controller: email,
                          decoration: InputDecoration(
                            hintText: "Adresse email",
                            prefixIcon: Icon(Icons.email),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Password
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: TextField(
                          controller: password,
                          obscureText: isHidden,
                          decoration: InputDecoration(
                            hintText: "Mot de passe",
                            prefixIcon: const Icon(Icons.lock),

                            suffixIcon: IconButton(
                              icon: Icon(
                                isHidden
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: (){
                                setState(() {
                                  isHidden = !isHidden;
                                });
                              },
                            ),

                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text("Mot de passe oublié?"),
                      ),

                      const SizedBox(height: 40),

                      /// Sign In Button
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
                              "Se connecter",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text("Ou connectez-vous avec"),

                      const SizedBox(height: 20),

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

                      const SizedBox(height: 30),

                      /// SignUp Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          const Text(
                            "Vous n'avez pas de compte?",
                          ),

                          GestureDetector(
                            onTap: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "S'inscrire",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        ],
                      ),

                      const SizedBox(height: 20),

                    ],
                  ),
                )

              ],
            ),
          ),
        ),
      ),
    );
  }


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
*/