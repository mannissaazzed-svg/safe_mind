import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestAuthPage extends StatelessWidget {
  const TestAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Auth Test")),
      body: Center(
        child: Text(
          user == null
              ? "NOT LOGGED IN"
              : "LOGGED IN: ${user.id}",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}