import 'package:flutter/material.dart';
import 'package:safemind/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safemind/screens/local_provider.dart';
import 'package:safemind/services/auth/auth_service.dart';
import 'package:safemind/screens/patient/home.dart';
import 'package:safemind/screens/soignant/caregiver_profile.dart';
import 'sign_up.dart';
import 'person.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isHidden  = true;
  bool _isLoading = false;

  final authService         = AuthService();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  
  void login() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    try {
      await authService.signInWithEmailPassword(email, password);
      String? role = await authService.getRole();
      if (!mounted) return;

      if (role == null) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const Person()));
      } else if (role == 'patient') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const Home()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(
                builder: (_) => const CaregiverProfileScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  
  void _showLanguagePicker(BuildContext context) {
    final provider = context.read<LocaleProvider>();

    final languages = [
      {'code': 'fr', 'flag': '🇫🇷', 'label': 'Français'},
      {'code': 'en', 'flag': '🇬🇧', 'label': 'English'},
      {'code': 'ar', 'flag': '🇩🇿', 'label': 'العربية'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre décorative
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'Langue / Language / اللغة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ),
            ...languages.map((lang) {
              final isSelected =
                  provider.locale.languageCode == lang['code'];
              return ListTile(
                leading: Text(lang['flag']!,
                    style: const TextStyle(fontSize: 28)),
                title: Text(
                  lang['label']!,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFF467FB3)
                        : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle,
                        color: Color(0xFF467FB3))
                    : null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: isSelected
                    ? const Color(0xFF467FB3).withOpacity(0.08)
                    : null,
                onTap: () {
                  provider.setLocale(Locale(lang['code']!));
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l  = AppLocalizations.of(context)!;
    final lp = context.watch<LocaleProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff9F9999), Color(0xff467FB3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [

                
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Align(
                    alignment: lp.isArabic
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => _showLanguagePicker(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  Colors.white.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lp.locale.languageCode == 'fr'
                                  ? '🇫🇷'
                                  : lp.locale.languageCode == 'en'
                                      ? '🇬🇧'
                                      : '🇩🇿',
                              style:
                                  const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lp.locale.languageCode
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

               
                Text(
                  l.welcome,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 60),

               
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xffB7BCC0),
                        Color(0xff559ACA)
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Column(
                    children: [

                      
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: l.emailHint,
                            prefixIcon:
                                const Icon(Icons.email),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.all(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                     
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _isHidden,
                          decoration: InputDecoration(
                            hintText: l.passwordHint,
                            prefixIcon:
                                const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_isHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _isHidden = !_isHidden),
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.all(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment: lp.isArabic
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Text(
                          l.forgotPassword,
                          style: const TextStyle(
                              color: Colors.white70),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Bouton connexion
                      SizedBox(
                        width: 220,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xffF37D7D),
                                  Color(0xff594444),
                                ],
                              ),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ))
                                  : Text(
                                      l.signIn,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(l.orWith,
                          style: const TextStyle(
                              color: Colors.white)),

                      const SizedBox(height: 20),

                      // Icônes sociales
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          _socialIcon(
                              FontAwesomeIcons.apple,
                              Colors.black,
                              () async => await authService
                                  .signInWithApple()),
                          const SizedBox(width: 20),
                          _socialIcon(
                              FontAwesomeIcons.google,
                              Colors.red,
                              () async => await authService
                                  .signInWithGoogle()),
                          const SizedBox(width: 20),
                          _socialIcon(
                              FontAwesomeIcons.facebook,
                              Colors.blue,
                              () async => await authService
                                  .signInWithFacebook()),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Inscription
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(l.noAccount,
                              style: const TextStyle(
                                  color: Colors.white)),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const SignUpPage()),
                            ),
                            child: Text(
                              l.signUp,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration:
                                    TextDecoration.underline,
                              ),
                            ),
                          ),
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

  Widget _socialIcon(
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8)
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

