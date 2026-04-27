import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/screens/login.dart';
import 'package:safemind/screens/person.dart';
import 'package:safemind/screens/patient/home.dart';
import 'package:safemind/screens/soignant/formulaire.dart';
import 'package:safemind/screens/soignant/caregiver.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>?> getUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return null;

    final response = await supabase
        .from('users')
        .select('role, patient_filled')
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return const LoginPage();
    }

    return FutureBuilder(
      future: getUserData(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        final role = data?['role'];
        final filled = data?['patient_filled'] ?? false;

        // ❗ لم يحدد الدور
        if (role == null) {
          return const Person();
        }

        // ❗ مرافق ولم يملأ الفورم
        if (role == "caregiver" && filled == false) {
          return const PatientForm();
        }

        // ✔ مريض
        if (role == "patient") {
          return const Home();
        }

        // ✔ مرافق بعد الملء
        return Caregiver(diseaseType: "Parkinson");
      },
    );
  }
}
/*

/*

Auth Gate - This will continuously listen for auth state changes.

--------------------------------------------------------------------

unauthenticated -> Login Page
authenticated -> Person

*/
import 'package:flutter/material.dart';
import 'package:safemind/screens/login.dart';
import 'package:safemind/screens/person.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // Listen to auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange,

      // Build appropriate page based on auth state
      builder: (context, snapshot) {
        // loading..
        if (snapshot.connectionState == ConnectionState.waiting){
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // check if there is a valid session currently
        final session = snapshot.hasData ? snapshot.data!.session : null;
        if (session != null){
          return Person();
        } else {
          return LoginPage();
        }
      },
    );
  }
}
*/