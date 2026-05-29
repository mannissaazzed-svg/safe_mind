
import 'package:flutter/material.dart';
import 'package:safemind/screens/patient/patient_profile.dart';
import 'package:safemind/screens/soignant/caregiver_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/screens/login.dart';
import 'package:safemind/screens/person.dart';
import 'package:safemind/screens/patient/home.dart';
import 'package:safemind/screens/soignant/formulaire.dart';
import 'package:safemind/screens/soignant/caregiver.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    return await Supabase.instance.client
        .from('users')
        .select('role, patient_filled, disease, linked_to, full_name')
        .eq('id', user.id)
        .maybeSingle();
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return const LoginPage();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xff467EB3),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final data     = snapshot.data;
        final role     = data?['role'] as String?;
        final filled   = data?['patient_filled'] as bool? ?? false;
        final disease  = data?['disease'] as String? ?? '';
        final linkedTo = data?['linked_to'] as String?;
        final fullName = data?['full_name'] as String?;

       
        if (role == null || role.isEmpty) {
          return const Person();
        }

        
        if (role == 'patient') {
          if (fullName == null || fullName.isEmpty) {
            return const PatientProfileScreen(isFirstTime: true);
          }
          return const Home();
        }

       
        if (role == 'caregiver') {

          
          if (fullName == null || fullName.isEmpty || disease.isEmpty) {
            return const CaregiverProfileScreen(isFirstTime: true);
          }

         
          if (!filled) {
            return PatientForm(preselectedDisease: disease);
          }

          
          return Caregiver(diseaseType: disease);
        }

        
        return const LoginPage();
      },
    );
  }
}
