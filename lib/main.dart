import 'package:flutter/material.dart';
import 'package:safemind/screens/login.dart';
import 'package:safemind/screens/person.dart';
import 'package:safemind/screens/sign_up.dart';
import 'package:safemind/screens/splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://czqinrgsbmubzqddlqkz.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6cWlucmdzYm11YnpxZGRscWt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwOTU0NjIsImV4cCI6MjA5MTY3MTQ2Mn0.PFbwcQUWUZNPCM2H-P4N0qCV9rcKy-j8j7jlrGxCX0o",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Splash(),
    );
  }
}


