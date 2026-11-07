
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_config.dart';
import 'services/local_store.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.instance.init();
  await AuthService.instance.initialize();
  runApp(const LiftCareApp());
}

class LiftCareApp extends StatefulWidget {
  const LiftCareApp({super.key});

  @override
  State<LiftCareApp> createState() => _LiftCareAppState();
}

class _LiftCareAppState extends State<LiftCareApp> {
  Locale _locale = const Locale('en');
  bool _loading = true;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('app_language') ?? 'en';

    if (!mounted) return;

    setState(() {
      _locale = Locale(language);
      _signedIn = AuthService.instance.isSignedIn;
      _loading = false;
    });
  }

  Future<void> _setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language);

    if (mounted) {
      setState(() => _locale = Locale(language));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF155EEF),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: _loading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _signedIn
              ? HomeScreen(
                  locale: _locale,
                  onLanguageChanged: _setLanguage,
                  onSignOut: () async {
                    await AuthService.instance.signOut();
                    if (mounted) {
                      setState(() => _signedIn = false);
                    }
                  },
                )
              : AuthScreen(
                  locale: _locale,
                  onLanguageChanged: _setLanguage,
                  onSignedIn: () {
                    if (mounted) {
                      setState(() => _signedIn = true);
                    }
                  },
                ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final Locale locale;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onSignedIn;

  const AuthScreen({
    super.key,
    required this.locale,
    required this.onLanguageChanged,
    required this.onSignedIn,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  String? _error;

  String t(String en, String ml) {
    return widget.locale.languageCode == 'ml' ? ml : en;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await AuthService.instance.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );

      if (AuthService.instance.isSignedIn) {
        widget.onSignedIn();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: LanguageMenu(
                      locale: widget.locale,
                      onChanged: widget.onLanguageChanged,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Icon(
                    Icons.elevator_rounded,
                    size: 68,
                    color: Color(0xFF155EEF),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'LiftCare Pro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    t(
                      'Lift Maintenance Management',
                      'ലിഫ്റ്റ് മെയിന്റനൻസ് മാനേജ്മെന്റ്',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PR Lifts',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    t('Staff Login', 'സ്റ്റാഫ് ലോഗിൻ'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: t('Email', 'ഇമെയിൽ'),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            return (v == null || !v.contains('@'))
                                ? t(
                                    'Enter a valid email',
                                    'ശരിയായ ഇമെയിൽ നൽകുക',
                                  )
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: t('Password', 'പാസ്‌വേഡ്'),
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          validator: (v) {
                            return (v == null || v.length < 8)
                                ? t(
                                    'Enter your password (minimum 8 characters)',
                                    'കുറഞ്ഞത് 8 അക്ഷരമുള്ള പാസ്‌വേഡ് നൽകുക',
                                  )
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(t('Login', 'ലോഗിൻ')),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t(
                      'This first release is configured for PR Lifts. Staff accounts are created by the administrator. Public company registration is disabled until the multi-company release.',
                      'ഈ ആദ്യ പതിപ്പ് PR Lifts-നായി ക്രമീകരിച്ചിരിക്കുന്നു. സ്റ്റാഫ് അക്കൗണ്ടുകൾ അഡ്മിൻ സൃഷ്ടിക്കും. Multi-Company പതിപ്പ് തയ്യാറാകുന്നതുവരെ പൊതുവായ കമ്പനി രജിസ്ട്രേഷൻ പ്രവർത്തനരഹിതമാണ്.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'Internet is required to sign in. Offline service entry and sync features will be added in the upcoming phases.',
                      'ലോഗിൻ ചെയ്യാൻ ഇന്റർനെറ്റ് ആവശ്യമാണ്. ഓഫ്‌ലൈൻ സർവീസ് എൻട്രിയും സിങ്ക് സൗകര്യവും അടുത്ത ഘട്ടങ്ങളിൽ ചേർക്കും.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Locale locale;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onSignOut;

  const HomeScreen({
    super.key,
    required this.locale,
    required this.onLanguageChanged,
    required this.onSignOut,
  });

  String t(String en, String ml) {
    return locale.languageCode == 'ml' ? ml : en;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiftCare Pro'),
        actions: [
          LanguageMenu(
            locale: locale,
            onChanged: onLanguageChanged,
          ),
          IconButton(
            tooltip: t('Sign out', 'ലോഗ് ഔട്ട്'),
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF155EEF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Company workspace', 'കമ്പനി പ്രവർത്തനങ്ങൾ'),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 5),
                Text(
                  AuthService.instance.companyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  t(
                    'Company code: ${AuthService.instance.companyCode}',
                    'കമ്പനി കോഡ്: ${AuthService.instance.companyCode}',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            t('Dashboard', 'ഡാഷ്ബോർഡ്'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _Tile(
                icon: Icons.people_alt_outlined,
                title: t('Customers', 'കസ്റ്റമർമാർ'),
                subtitle: t('Next phase', 'അടുത്ത ഘട്ടം'),
              ),
              _Tile(
                icon: Icons.elevator_outlined,
                title: t('Lifts', 'ലിഫ്റ്റുകൾ'),
                subtitle: t('Next phase', 'അടുത്ത ഘട്ടം'),
              ),
              _Tile(
                icon: Icons.assignment_outlined,
                title: t('Service Reports', 'സർവീസ് റിപ്പോർട്ടുകൾ'),
                subtitle: t('Next phase', 'അടുത്ത ഘട്ടം'),
              ),
              _Tile(
                icon: Icons.engineering_outlined,
                title: t('Technicians', 'ടെക്നീഷ്യൻമാർ'),
                subtitle: t('Next phase', 'അടുത്ത ഘട്ടം'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Deployment', 'വിന്യാസം'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t(
                      'PR Lifts first. The data model is tenant-aware so additional companies can be enabled later without rebuilding the product from scratch.',
                      'ആദ്യം PR Lifts. ഭാവിയിൽ മറ്റ് കമ്പനികളെ ചേർക്കാൻ കഴിയുന്ന രീതിയിലാണ് ഡാറ്റാ ഘടന തയ്യാറാക്കുന്നത്.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(value: 0.25),
                  const SizedBox(height: 5),
                  Text(
                    t('Phase 1 foundation', 'Phase 1 അടിസ്ഥാന ഘട്ടം'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF155EEF),
              size: 27,
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageMenu extends StatelessWidget {
  final Locale locale;
  final ValueChanged<String> onChanged;

  const LanguageMenu({
    super.key,
    required this.locale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Language',
      initialValue: locale.languageCode,
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        PopupMenuItem(
          value: 'ml',
          child: Text('മലയാളം'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.language),
            const SizedBox(width: 4),
            Text(locale.languageCode == 'ml' ? 'മലയാളം' : 'EN'),
          ],
        ),
      ),
    );
  }
}
