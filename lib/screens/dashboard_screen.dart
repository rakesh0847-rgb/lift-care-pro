import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/customer_service.dart';
import '../services/local_store.dart';

class DashboardScreen extends StatefulWidget {
  final Locale locale;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onSignOut;

  const DashboardScreen({
    super.key,
    required this.locale,
    required this.onLanguageChanged,
    required this.onSignOut,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int customerCount = 0;
  int reportCount = 0;

  bool get isMalayalam =>
      widget.locale.languageCode == 'ml';

  String t(String en, String ml) =>
      isMalayalam ? ml : en;

  static const navy = Color(0xFF101B36);
  static const blue = Color(0xFF4169E1);
  static const background = Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final customers =
        await CustomerService.instance.getCustomers(
      AuthService.instance.companyCode,
    );

    final reports = LocalStore.instance.getRecords();

    if (!mounted) return;

    setState(() {
      customerCount = customers.length;
      reportCount = reports.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final company = AuthService.instance.companyName;
    final code = AuthService.instance.companyCode;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: navy,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.elevator_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LiftCare Pro',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        Text(
                          'Maintenance Management',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'en' || value == 'ml') {
                        widget.onLanguageChanged(value);
                      } else if (value == 'logout') {
                        widget.onSignOut();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                      const PopupMenuItem(
                        value: 'ml',
                        child: Text('മലയാളം'),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Text(t('Sign out', 'ലോഗ് ഔട്ട്')),
                      ),
                    ],
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.more_vert,
                        color: navy,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Company Card

              Container(
                padding: const EdgeInsets.all(23),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF172B59),
                      Color(0xFF4169E1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withOpacity(0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('COMPANY WORKSPACE', 'കമ്പനി'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      company,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Company ID: $code',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF8EF0C1),
                          size: 17,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          t('Workspace Active', 'പ്രവർത്തനക്ഷമം'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white70,
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Offline Ready',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                t('Overview', 'അവലോകനം'),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people_alt_rounded,
                      title: t('Customers', 'കസ്റ്റമേഴ്സ്'),
                      value: '$customerCount',
                      color: const Color(0xFF4169E1),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.assignment_rounded,
                      title: t('Reports', 'റിപ്പോർട്ടുകൾ'),
                      value: '$reportCount',
                      color: const Color(0xFF159D83),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                t('Management', 'മാനേജ്മെന്റ്'),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),

              const SizedBox(height: 15),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 13,
                mainAxisSpacing: 13,
                childAspectRatio: 1.12,
                children: [
                  _MenuCard(
                    icon: Icons.people_alt_rounded,
                    title: t('Customers', 'കസ്റ്റമേഴ്സ്'),
                    subtitle: t(
                      'Customer details',
                      'കസ്റ്റമർ വിവരങ്ങൾ',
                    ),
                    color: const Color(0xFF4169E1),
                  ),
                  _MenuCard(
                    icon: Icons.elevator_rounded,
                    title: t('Lifts', 'ലിഫ്റ്റുകൾ'),
                    subtitle: t(
                      'Lift management',
                      'ലിഫ്റ്റ് വിവരങ്ങൾ',
                    ),
                    color: const Color(0xFF8B5CF6),
                  ),
                  _MenuCard(
                    icon: Icons.assignment_rounded,
                    title: t('Service Reports', 'സർവീസ് റിപ്പോർട്ടുകൾ'),
                    subtitle: t(
                      'Monthly maintenance',
                      'മാസ സർവീസ്',
                    ),
                    color: const Color(0xFF159D83),
                  ),
                  _MenuCard(
                    icon: Icons.engineering_rounded,
                    title: t('Technicians', 'ടെക്നീഷ്യൻമാർ'),
                    subtitle: t(
                      'Staff management',
                      'സ്റ്റാഫ് വിവരങ്ങൾ',
                    ),
                    color: const Color(0xFFE59A36),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      color: blue,
                      size: 30,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('Offline Data Protection',
                                'ഓഫ്‌ലൈൻ ഡാറ്റ സംരക്ഷണം'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            t(
                              'Your data stays on this device.',
                              'നിങ്ങളുടെ ഡാറ്റ ഈ ഉപകരണത്തിൽ തന്നെ സൂക്ഷിക്കുന്നു.',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Center(
                child: Text(
                  'LIFTCARE PRO  •  VERSION 1.0',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.3,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE9EDF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF101B36),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
