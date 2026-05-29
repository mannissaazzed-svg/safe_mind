import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:safemind/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/screens/local_provider.dart';
import 'package:safemind/services/auth/auth_gate.dart';
import 'package:safemind/screens/splash.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://czqinrgsbmubzqddlqkz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6cWlucmdzYm11YnpxZGRscWt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwOTU0NjIsImV4cCI6MjA5MTY3MTQ2Mn0.PFbwcQUWUZNPCM2H-P4N0qCV9rcKy-j8j7jlrGxCX0o',
  );

  

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'SafeMind',
      debugShowCheckedModeBanner: false,

      // ── Langue active ──────────────────────────────
      locale: localeProvider.locale,

      // ── Langues supportées ─────────────────────────
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ],

      // ── Delegates de localisation ──────────────────
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── RTL automatique pour l'arabe ───────────────
      builder: (context, child) {
        return Directionality(
          textDirection: localeProvider.isArabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },

      home: const Splash(),
    );
  }
}
