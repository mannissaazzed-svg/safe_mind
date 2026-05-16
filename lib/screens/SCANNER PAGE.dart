import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:safemind/screens/medecin/ordonnance_page.dart';

class QrScannerPage extends StatelessWidget {
  const QrScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner Ordonnance")),

      body: MobileScanner(
        onDetect: (capture) async {
          final code = capture.barcodes.first.rawValue;

          if (code == null) return;

          try {
            final data = jsonDecode(code);

            final res = await Supabase.instance.client
                .from('ordonnances')
                .select()
                .eq('id', data['id'])
                .maybeSingle();

            if (res != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrdonnancePage(),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("QR invalide")),
            );
          }
        },
      ),
    );
  }
}