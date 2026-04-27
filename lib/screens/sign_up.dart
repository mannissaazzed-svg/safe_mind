import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safemind/services/auth/auth_service.dart';
import 'package:safemind/screens/person.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool isHidden = true;

  // get auth service
  final authService = AuthService();

  // text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordContruoller = TextEditingController();

  void signUp() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  try {
    await authService.signUpWithEmailPassword(email, password);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Person()),
    );

  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("$e")));
  }
}

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
              colors: [Color(0xff9F9999), Color(0xff467FB3)]),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),

                /// Title
                const Text(
                  "Créez votre compte",
                  style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Serif"),
                ),

                const SizedBox(height: 30),

                /// Form Container
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xffB7BCC0), Color(0xff559ACA)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      /// Email Field
                      buildInputContainer(
                        child: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            hintText: "Adresse email",
                            prefixIcon: Icon(Icons.email),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Password Field
                      buildInputContainer(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: isHidden,
                          decoration: InputDecoration(
                            hintText: "Mot de passe",
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => isHidden = !isHidden),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Confirm Password Field
                      buildInputContainer(
                        child: TextField(
                          controller: _confirmPasswordContruoller,
                          obscureText: isHidden,
                          decoration: InputDecoration(
                            hintText: "Confirmez le mot de passe",
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => isHidden = !isHidden),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),

                    
                      const SizedBox(height: 45),

                      /// Sign Up Button
                      SizedBox(
                        width: 220,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: signUp,
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
                                colors: [Color(0xffF37D7D), Color(0xff594444)],
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                "S'inscrire",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Ou inscrivez-vous en utilisant",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),

                      const SizedBox(height: 20),

                      /// Social Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          socialIcon(FontAwesomeIcons.apple, Colors.black),
                          const SizedBox(width: 20),
                          socialIcon(FontAwesomeIcons.google, Colors.red),
                          const SizedBox(width: 20),
                          socialIcon(FontAwesomeIcons.facebook, Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 20),
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

  
  Widget buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  Widget socialIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}












